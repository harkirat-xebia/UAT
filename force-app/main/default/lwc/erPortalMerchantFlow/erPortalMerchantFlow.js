/*************************************************************************************
LWC Name:     erPortalMerchantFlow
Version:      1.0
Created Date: 15/02/2021
Purpose:      Main component for Merchant auto enrollment.

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           15/02/2021  Initial (Auto enrollment Project)
*************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

// Apex methods
import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getEnterpriseInfos2 from '@salesforce/apex/GenericWithoutSharing.getEnterpriseInfos2';
import checkContractNb from '@salesforce/apex/GenericWithoutSharing.checkContractNb';
import checkCity from '@salesforce/apex/APER30_AutoEnrollment_Management.checkCity';
import getFinancialConditions from '@salesforce/apex/GenericWithoutSharing.getFinancialConditions';
import getBIC from '@salesforce/apex/APER30_AutoEnrollment_Management.getBIC';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';
import upsertLead from '@salesforce/apex/APER30_AutoEnrollment_Management.upsertLead';
import getTermsAndConditions from '@salesforce/apex/APER30_AutoEnrollment_Management.getTermsAndConditions';
import updateAccount from '@salesforce/apex/GenericWithoutSharing.updateAccount';
import getFinCentersInfos from '@salesforce/apex/GenericWithoutSharing.getFinCentersInfos';
// import saveToFile from '@salesforce/apex/GenericWithoutSharing.saveToFile';
import getOnBoardingDatas from '@salesforce/apex/GenericWithoutSharing.getOnBoardingDatas';

// import getAcceptorModels from "@salesforce/apex/APER30_AutoEnrollment_Management.getAcceptorModels";
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
// import getStoresInfos from '@salesforce/apex/GenericWithoutSharing.getStoresInfos';
// import checkExistingTID from '@salesforce/apex/GenericWithoutSharing.checkExistingTID';
// import saveToFile from '@salesforce/apex/GenericWithoutSharing.saveToFile';

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
  isValidTID,
  debugLog,
  buildTemplate
} from 'c/erPortalUtils';

export default class ErPortalMerchantFlow extends LightningElement {
  currentPageReference = null;
  urlStateParameters = null;

  @api country; // Parameter to be set in the builder for the page variation dedicated to the country
  @api lang; // Lang parameter get from url
  @api locale; // Locale parameter get from url
  @api solution; // Product parameter get from url
  @api sourceId; // sourceId to link merchant to a particular campaign
  @api uniqueKeyId; // Unique Key ID for Webform offer and Auto enrollment v2 Onboarding
  @api version; // used to detect if Auto enrollment v2
  @api dbg; // Debug mode (to enable logs display)
  // @api isFromWebOffer; // Parameter added when url is from quote web offer
  scope = 'M'; // Merchant scope
  currentStep = '1';
  stepValidated;

  subscription = null; // used for recaptcha component
  isRecaptchaSuccess;
  @wire(MessageContext)
  messageContext;

  showSpinner;
  isReadOnly;
  isReadOnlyEditable;
  ongoingProcess;
  activatedContract;
  hasContract;
  expiredQuote;
  showWelcomeMsg;
  onboardingAccount;
  contractNbChecked;
  isConvertedLead;

  // Labels for fields, format patterns, error messages
  @track labels = {};
  labelsAllLangs = {};
  isSandbox;

  // Picklist values
  @track picklistGroup = {};

  hasCheckedEnterpriseNb;
  @track merchantInfos = {};

  @track financialConditions = [];
  @track finCenterInfos = {};

  hasPromoCode;
  hasNoBillingAccount = true;
  isValidIBAN;
  savFinCenterBtnDisabled = true;
  showFinCenterdetails = true;

  @track tableLabels = {};

  // List of displayed column names in data tables (financial centers, stores & terminals)
  @track finCentersListTableColumns = {};
  @track storesListTableColumns = {};
  @track merchantUsersListTableColumns = {};
  @track terminalsListTableColumns = {};

  @track merchantUserInfos = {};
  @track storeInfos = {};
  terminalProvidersAndModels = {};

  // Store categories (Dependant values)
  @track categories = {};
  @track categorieItems = [];
  @track chosenCategories = [];

  // Terms & conditions
  @track termsAndConditions = {};

  hasAcceptedConditions;

  @track companyInfos = [];
  // onboardingEndMessage = '';
  isStepUsers;

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
    this.sourceId = this.urlStateParameters.sourceId;
    this.dbg = this.urlStateParameters.dbg === "true" ? true : false;

    this.locale = this.urlStateParameters.language;
    this.uniqueKeyId = this.urlStateParameters.key;
    if (!this.uniqueKeyId) this.showWelcomeMsg = true;
    // this.version = (this.urlStateParameters.v) ? this.urlStateParameters.v : null;
    this.version = 2; // TODO to be changed (UAT)
  }

  async connectedCallback() {
    let pkGrp = this.picklistGroup;
    pkGrp.uiLang =
      pkGrp.country =
      pkGrp.salutation =
      pkGrp.lang =
      pkGrp.role =
      pkGrp.refundSalutation =
      pkGrp.refundLang =
      pkGrp.refundRole =
      pkGrp.refundCountry =
      pkGrp.storeCountry =
      pkGrp.yesNo =
      pkGrp.isFranchisee =
      pkGrp.sector =
      pkGrp.storeContactSalutation =
      pkGrp.storeContactLang =
      pkGrp.userSalutation =
      pkGrp.userLang =
      pkGrp.terminalProvider =
      pkGrp.terminalModel =
      pkGrp.isLinkedToCashReg =
      pkGrp.terminalType =
        [];

    this.subscribeToMessageChannel(); // Subscribe to recaptcha message service

    // Get all labels for fields, messages, etc...
    getLabels({ country: this.country, scope: this.scope })
      .then((data) => {
        this.labelsAllLangs = data;
        this.isSandbox = data.All.isSandbox;
        debugLog(this.dbg, '>>> getLabels() - this.isSandbox ' + this.isSandbox);
        this.switchLanguage(this.lang);

        debugLog(this.dbg, '>>> connectedCallback() - this.isWebOffer ' + this.isWebOffer);
        debugLog(this.dbg, '>>> connectedCallback() - this.uniqueKeyId ' + this.isOnBoarding);
        debugLog(this.dbg, '>>> connectedCallback() - this.uniqueKeyId ' + this.uniqueKeyId);
        if ((this.isWebOffer || this.isOnBoarding) && this.uniqueKeyId) {
          // Web offer or on boarding use case
          debugLog(this.dbg, '>>> connectedCallback() - *** Start getEnterpriseInfos2 *** ');

          getEnterpriseInfos2({
            enterpriseNb: null,
            country: this.country,
            lang: this.lang,
            uniqueKeyId: this.uniqueKeyId,
            userEmail: null,
            solutionCode: this.solution
          })
            .then((data) => {
              debugLog(this.dbg, '>>> getEnterpriseInfos2() - data ' + JSON.stringify(data));
              this.merchantInfos = {};
              this.merchantInfos.storesList = [];
              this.merchantInfos.finCentersList = [];

              Object.keys(data).forEach((key) => {
                this.merchantInfos[key] = data[key];
              });

              this.activatedContract = this.merchantInfos.Activated; // Show message already have active contract for weboffer
              this.hasContract = this.merchantInfos.contractId;
              debugLog(this.dbg, '>>> getEnterpriseInfos2() - this.activatedContract ' + this.activatedContract);

              if (!this.activatedContract) {
                this.showWelcomeMsg = true;
                this.hasCheckedEnterpriseNb = true;

                // Init picklist with right value
                pkGrp.country = initPicklistValue(
                  JSON.parse(JSON.stringify(pkGrp.country)),
                  this.merchantInfos.country
                ); // TODO move this part to Utils as initSelectPicklist() function
                pkGrp.refundCountry = initPicklistValue(pkGrp.refundCountry, this.merchantInfos.refundCountry);
                pkGrp.storeCountry = initPicklistValue(pkGrp.storeCountry, this.merchantInfos.storeCountry);

                // Init picklist with right value
                pkGrp.salutation = initPicklistValue(pkGrp.salutation, this.merchantInfos.salutation);
                pkGrp.lang = initPicklistValue(pkGrp.lang, this.merchantInfos.lang);
                pkGrp.role = initPicklistValue(pkGrp.role, this.merchantInfos.role);

                if (!this.isOnBoarding) {
                  this.handleFinancialConditions();
                  this.hasPromoCode = this.uniqueKeyId && this.merchantInfos.promoCode; // Show promocode in weboffer if available
                }

                // if(this.uniqueKeyId) {  // Add temporary use case of countries without public register (ES)
                // Get financial center infos if existing account
                if (this.merchantInfos.accountId) {
                  getFinCentersInfos({ accountId: this.merchantInfos.accountId })
                    .then((data) => {
                      debugLog(this.dbg, '>>> getFinCentersInfos() - accountId ' + this.merchantInfos.accountId);
                      debugLog(this.dbg, '>>> getFinCentersInfos() - data ' + JSON.stringify(data));
                      data.forEach((elem, index) => {
                        let finCenter = {};
                        finCenter.noDelete = true; // to hide delete button in data table
                        Object.keys(elem).forEach((key) => {
                          finCenter[key] = elem[key];
                        });
                        finCenter.finCenterId = index + 1;
                        this.merchantInfos.finCentersList.push(finCenter);
                      });
                      debugLog(
                        this.dbg,
                        '>>> getFinCentersInfos() - this.merchantInfos.finCentersList.length ' +
                          this.merchantInfos.finCentersList.length
                      );

                      if (this.merchantInfos.finCentersList.length > 0) {
                        this.finCenterInfos = JSON.parse(JSON.stringify(this.merchantInfos.finCentersList[0]));
                        pkGrp.refundSalutation = initPicklistValue(
                          pkGrp.refundSalutation,
                          this.finCenterInfos.refundSalutation
                        );
                        pkGrp.refundLang = initPicklistValue(pkGrp.refundLang, this.finCenterInfos.refundLang);
                        pkGrp.refundRole = initPicklistValue(pkGrp.refundRole, this.finCenterInfos.refundRole);
                        this.setRowIndex(this.finCenterInfos, this.merchantInfos.finCentersList, 'finCenterId');
                      }
                      debugLog(
                        this.dbg,
                        '>>> getFinCentersInfos() - this.merchantInfos.finCentersList ' +
                          JSON.stringify(this.merchantInfos.finCentersList)
                      );

                      this.showSpinner = false;
                      debugLog(this.dbg, '>>> getFinCentersInfos -- this.showSpinner2: ' + this.showSpinner);
                    })
                    .catch((error) => {
                      debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
                    });
                }
              }

              if (this.isOnBoarding) {
                this.retrieveOnboardingDatas();
                this.currentStep = null;
              }
            })
            .catch((error) => {
              this.expiredQuote = true;
              this.showSpinner = false;
              debugLog(this.dbg, '>>> getEnterpriseInfos2()1 - error ' + JSON.stringify(error));
            });
        }

        debugLog(true, '>>> connectedCallback() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getLabels() - error ' + error);
      });
  }

  // Initialise all the number of steps and their respective name
  get stepList() {
    return [
      { nb: '1', label: this.labels.lb_step1 },
      { nb: '2', label: this.labels.lb_step2 },
      { nb: '3', label: this.labels.lb_step3 }
    ];
  }

  get phase() {
    let phaseTable = {
      1: '1',
      2: '2',
      3: '2',
      4: '3',
      5: '3',
      6: '3',
      7: '3',
      8: '',
      null: '2'
    };
    return phaseTable[this.currentStep];
  }
  // Initialise all the number of steps and their respective name
  // get backgroundImage() {
  //   return "background-image: url('/resource/SRER_Portal/img/wood-lightgrey.jpg');background-size: cover;padding: 0.3rem;";
  // }

  get isStepOne() {
    return this.currentStep === '1';
  }
  get isStepTwo() {
    return this.currentStep === '2';
  }
  get isStepThree() {
    return this.currentStep === '3';
  }
  get isStepFour() {
    return this.currentStep === '4';
  }
  get isStepFive() {
    return this.currentStep === '5';
  }
  get isStepSix() {
    return this.currentStep === '6';
  }
  get isStepSeven() {
    return this.currentStep === '7';
  }
  get isEndPage() {
    return this.currentStep === '8';
  }

  get isEnableNext() {
    debugLog(true, '>>> isEnableNext() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);

    return (
      (this.hasCheckedEnterpriseNb &&
        (!this.activatedContract || !this.hasContract) &&
        !this.expiredQuote &&
        ((!['7', '8'].includes(this.currentStep) && !this.isReadOnly) ||
          (!['6', '8'].includes(this.currentStep) && this.isReadOnly))) ||
      (this.isOnBoarding && ['2', '8'].includes(this.currentStep))
    );
    // !this.isOnBoarding;
  }

  get isEnablePrev() {
    return this.currentStep != '1' && this.currentStep != '2' && this.currentStep != '8' && !this.isOnBoarding;
  }

  get isEnableFinish() {
    return (
      (this.currentStep === '7' && this.hasAcceptedConditions) ||
      (this.currentStep === '6' && this.isReadOnly) ||
      this.isOnBoarding
    ); //TODO to be completed for onboarding process (validate should be greyed when on main page and not all required datas are fulfilled)
  }

  get hasStore() {
    return this.merchantInfos.storesList.length > 0;
  }

  get hasFinCenter() {
    return this.merchantInfos.finCentersList.length > 0;
  }

  get hasMultipleFinCenter() {
    return this.merchantInfos.finCentersList.length > 1;
  }

  get displayFiscalId() {
    return this.merchantInfos.countryCode === 'LU';
  }

  get showMsg() {
    return (
      (this.activatedContract && !this.onboardingAccount && this.hasContract) ||
      this.expiredQuote ||
      this.merchantInfos.badUserEmail ||
      this.ongoingProcess
    );
  }

  get infoMsg() {
    debugLog(this.dbg, '>>> infoMsg() - this.merchantInfos ' + JSON.stringify(this.merchantInfos));
    return (this.activatedContract && !this.onboardingAccount && this.hasContract) || this.ongoingProcess
      ? this.labels.lb_err_msg_existing_company
      : this.expiredQuote
      ? this.labels.lb_err_msg_expired_quote
      : this.merchantInfos.badUserEmail == 'true'
      ? buildTemplate(this.labels.lb_err_msg_bad_user, [this.merchantInfos.mainContact])
      : null;
    // this.onboardingAccount && this.contractNbChecked ? this.labels.onboardingEndMessage :
  }

  get showAddFinCenter() {
    return this.merchantInfos.finCentersList.length && !this.isReadOnly;
  }

  get isWebOffer() {
    return this.uniqueKeyId ? true : false; // to distinguish Web offer from Auto enrollment v2 (that also have a uniqueKeyId on Onboarding part)
  }

  get isReadOnlyPromoCode() {
    return this.isReadOnly || this.isWebOffer;
  }

  get isOnBoarding() {
    return this.contractNbChecked;
  }

  get currentStore() {
    const storeIndex = this.merchantInfos.storesList.findIndex((store) => store.storeId === this.storeInfos.storeId);
    this.merchantInfos.storesList[storeIndex].storeIndex = storeIndex;
    return this.merchantInfos.storesList[storeIndex];
  }

  switchLanguage(lang) {
    this.lang = lang;
    this.labels = {
      ...this.labelsAllLangs[this.lang],
      ...this.labelsAllLangs['All']
    };
    this.tableLabels.lb_edit = this.labels.lb_edit;
    this.tableLabels.lb_delete = this.labels.lb_delete;

    // Init store and terminal data tables headers
    this.finCentersListTableColumns = {
      name: this.labels.lb_step2_fin_center,
      contact: this.labels.lb_step2_contact,
      iban: this.labels.lb_step2_iban,
      fullAddress: this.labels.lb_step2b_store_address
    };

    this.storesListTableColumns = {
      name: this.labels.lb_step2b_store,
      fullAddress: this.labels.lb_step2b_store_address,
      finCenterName: this.labels.lb_step2_fin_center
    };

    this.merchantUsersListTableColumns = {
      userName: this.labels.lb_step2b_user,
      userEmail: this.labels.lb_step1_email,
      contractNb: this.labels.lb_contract_nb
    };

    this.terminalsListTableColumns = {
      terminalProvider: this.labels.lb_step2b_terminal_provider,
      terminalModelDisplayValue: this.labels.lb_step2b_terminal_model,
      tid: this.labels.lb_step2b_tid,
      cashRegisterProvider: this.labels.lb_step2b_cash_register_provider,
      isLinkedToCashRegDisplayValue: this.labels.lb_step2b_is_linked_to_cash_register,
      mid2: this.labels.lb_mastercard_mid
    };

    this.setPicklistInfos();
    if ((this.hasCheckedEnterpriseNb || this.isWebOffer) && !this.isOnBoarding) this.handleFinancialConditions();

    if (this.currentStep == '4') {
      this.merchantInfos.storesList.forEach((store) => {
        if (store.terminalInfos.terminalProvider) this.setTIDPlaceholder(store);
      });
    }
    if (this.currentStep == '5') this.initCategories();
    if (this.currentStep == '7') this.initTermsAndConditions();
    if (this.isOnBoarding && this.merchantInfos.company) this.initCompanyInfos();

    this.template.querySelector('c-er-portal-merchant-on-boarding')?.switchLanguage(this.lang);

  }

  setPicklistInfos() {
    getPicklistInfos({
      country: this.country,
      lang: this.lang,
      scope: this.scope
    })
      .then((data) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - data ' + JSON.stringify(data));

        // Set language picklist of the header first
        this.picklistGroup.uiLang = formatPicklist(data.pk_lang_list, this.lang);
        publish(this.messageContext, languageList, this.picklistGroup.uiLang);

        this.picklistGroup.country = formatPicklist(data.pk_country, this.merchantInfos.country);
        this.picklistGroup.role = formatPicklist(data.pk_role, this.merchantInfos.role);
        this.picklistGroup.lang = formatPicklist(data.pk_lang, this.merchantInfos.lang);
        this.picklistGroup.salutation = formatPicklist(data.pk_salutation, this.merchantInfos.salutation);

        // Picklist for refund contact
        this.picklistGroup.refundSalutation = formatPicklist(data.pk_salutation, this.finCenterInfos.refundSalutation);
        this.picklistGroup.refundLang = formatPicklist(data.pk_lang, this.finCenterInfos.refundLang);
        this.picklistGroup.refundRole = formatPicklist(data.pk_role, this.finCenterInfos.refundRole);
        this.picklistGroup.refundCountry = formatPicklist(data.pk_country, this.finCenterInfos.refundCountry);

        // Picklist for stores
        this.picklistGroup.storeCountry = formatPicklist(data.pk_country);
        this.picklistGroup.isFranchisee = formatPicklist(data.pk_yes_no);
        // this.picklistGroup.sector = this.solution.startsWith('TR')
        this.picklistGroup.sector = this.solution.match(/ERBE_TR.*|ERLU_TR.*/)
          ? formatPicklist(data.pk_sector)
          : formatPicklist(data.pk_sector_tce_tre);
        this.picklistGroup.storeContactSalutation = formatPicklist(data.pk_salutation);
        this.picklistGroup.storeContactLang = formatPicklist(data.pk_lang);

        debugLog(this.dbg, '>>> setPicklistInfos() - 1');
        // Picklist for users
        this.picklistGroup.userSalutation = formatPicklist(data.pk_salutation);
        this.picklistGroup.userLang = formatPicklist(data.pk_lang);

        debugLog(this.dbg, '>>> setPicklistInfos() - 1');
        // Picklist for terminals
        this.picklistGroup.isLinkedToCashReg = formatPicklist(data.pk_yes_no);
        this.picklistGroup.terminalType = formatPicklist(data.pk_terminal_type);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
      });
  }

  handleNext() {
    this.validateStep();
    debugLog(this.dbg, 'handleNext, stepValidated: ' + this.stepValidated);
    if (this.stepValidated) {
      // TODO create separate methods for each step in order to lighten the code
      switch (this.currentStep) {
        case '1':
          if (!this.merchantInfos.solution) this.merchantInfos.solution = this.solution;
          debugLog(this.dbg, 'handleNext - upsertLead. this.merchantInfos = ' + JSON.stringify(this.merchantInfos));

          if (this.version) {
            this.initTermsAndConditions(); // Auto enrollment v2 - prepare terms & conditions
            // this.retrieveOnboardingMsg();
          }
          if (
            !this.isReadOnly &&
            !this.isWebOffer &&
            !this.activatedContract &&
            !this.ongoingProcess &&
            !this.isConvertedLead
          ) {
            // Do lead conversion: first, update lead then do conversion
            doApexEvent({ operationName: 'upsertLead', operationParams: JSON.stringify(this.merchantInfos) })
              .then((data) => {
                debugLog(this.dbg, '>>> convertLead() Update - data ' + JSON.stringify(data));
                debugLog(this.dbg, '>>> convertLead() Update - this.merchantInfos.leadId ' + this.merchantInfos.leadId);

                if (this.merchantInfos.keyId == undefined) this.merchantInfos.keyId == '';
                doApexEvent({
                  operationName: 'convertLead',
                  operationParams:
                    '{"leadId": "' +
                    this.merchantInfos.leadId +
                    '", "countryCode": "' +
                    this.country +
                    '", "solution": "' +
                    this.solution +
                    '", "scope": "' +
                    this.scope +
                    '", "promoCode": "' +
                    this.merchantInfos.promoCode +
                    '", "keyId": "' +
                    this.merchantInfos.keyId +
                    '", "enterpriseNb": "' +
                    this.merchantInfos.enterpriseNb +
                    '"}'
                })
                  .then((data) => {
                    this.isConvertedLead = true;
                    debugLog(this.dbg, '>>> convertLead() Convert - data ' + JSON.stringify(data));
                  })
                  .catch((error) => {
                    debugLog(this.dbg, '>>> convertLead() - error ' + error);
                  });

                this.currentStep = '2';
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> convertLead() - error ' + error);
              });
          } else if (this.isWebOffer || (this.ongoingProcess && !this.hasContract) || this.isConvertedLead) {
            updateAccount({
              merchantInfosJSON: JSON.stringify(this.merchantInfos)
            })
              .then((data) => {
                this.currentStep = '2';
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> updateAccount() - error ' + error);
              });
            // this.isReadOnlyEditable = true;
          }

          if (this.isReadOnly || this.isWebOffer || this.isOnBoarding) {
            this.currentStep = '2';
          }
          break;

        case '2':
          debugLog(this.dbg, '>>> createFinCenters() - before ' + JSON.stringify(this.merchantInfos.finCentersList));
          if (!this.isReadOnly) {
            doApexEvent({
              operationName: 'createFinCenters',
              operationParams: this.merchantInfos.leadId + '|' + JSON.stringify(this.merchantInfos.finCentersList)
            })
              .then((data) => {
                debugLog(this.dbg, '>>> createFinCenters() - data ' + JSON.stringify(data));
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> createFinCenters() - error ' + error);
              });

            if (!this.isWebOffer) {
              // Skip opportunity update for web offers
              this.merchantInfos.promoCode = this.merchantInfos.promoCode ? this.merchantInfos.promoCode : '';
              this.updateOpportunity();
            }
          }

          debugLog(this.dbg, 'handleNext, this.version: ' + this.version);

          if (!this.version) {
            // Auto enrollment v1 if version not defined
            // Prepare Acceptor picklist datas ahead for the next step
            this.retrieveAcceptorModels();

            if (this.isWebOffer) this.isReadOnlyEditable = true;

            this.currentStep = '3';
          } else {
            // Auto enrollment v2
            // Prepare onboarding URL for the final step
            this.currentStep = '7';
          }
          break;

        // case "3":
        //   debugLog(this.dbg, ">>> createStores() *** START *** storesList: " + JSON.stringify(this.merchantInfos.storesList));
        //   if(!this.isReadOnly){
        //       this.merchantInfos.storesList.forEach((store) => {  store.chosenCategories = JSON.parse(JSON.stringify(this.chosenCategories));
        //                                                           store.categorieItemsIds = this.categorieItems.map(cat => cat.id);} ); // categorieItemsIds is used to delete previous categories selected for current solution
        //     debugLog(this.dbg, ">>> createStores() - before create: " + JSON.stringify(this.merchantInfos.storesList));
        //     doApexEvent({ operationName: 'createStores', operationParams: this.merchantInfos.leadId + '|' + JSON.stringify(this.merchantInfos.storesList) })
        //     .then((data) => {
        //       debugLog(this.dbg, ">>> createStores() - data " + JSON.stringify(data));
        //     })
        //     .catch((error) => { debugLog(this.dbg, ">>> createStores() - error " + error); });
        //   }

        //   if(this.isOnBoarding){
        //     this.currentStep = null;
        //   } else {
        //     // Retrieve categories in terminals step in order prepare datas ahead
        //     this.initCategories();
        //     this.currentStep = "4";
        //   }

        //   break;

        case '4':
          if (!this.isOnBoarding) {
            debugLog(this.dbg, '>>> createTerminals() - before ' + JSON.stringify(this.merchantInfos.storesList));
            doApexEvent({
              operationName: 'createTerminals',
              operationParams: this.merchantInfos.leadId + '|' + JSON.stringify(this.merchantInfos.storesList)
            })
              .then((data) => {
                debugLog(this.dbg, '>>> createTerminals() - data ' + JSON.stringify(data));
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> createTerminals() - error ' + error);
              });

            this.currentStep = !this.isReadOnly ? '5' : '6';
          } else {
            this.currentStep = '3';
          }

          break;

        case '5':
          // Prepare arrays for chosen categories
          // this.merchantInfos.storesList.forEach((store) => {
          // this.chosenCategories.push(...this.categorieItems.filter((elem) => elem.isChecked));
          // debugLog(this.dbg, ">>> Chosen cats - nb chosenCategories" + this.chosenCategories.length);
          // });

          // Get Terms and conditions previously
          if (!this.isOnBoarding) this.initTermsAndConditions();

          this.currentStep = '6';
          break;

        case '6':
          // debugLog(this.dbg, ">>> Step7 - createCategories() - this.merchantInfos.storesList " + JSON.stringify(this.merchantInfos.storesList));
          // debugLog(this.dbg, ">>> Step7 - createCategories() - this.isReadOnly " + this.isReadOnly );
          // if(!this.isReadOnly){
          //   let merchantId = (this.merchantInfos.leadId) ? this.merchantInfos.leadId : this.merchantInfos.accountId;  // In case of Weboffer, pass account Id (as may be no lead Id available)
          //   debugLog(this.dbg, ">>> Step7 - createCategories() - merchantId " + merchantId);
          //   doApexEvent({ operationName: 'createCategories', operationParams: merchantId + '|' + JSON.stringify(this.merchantInfos.storesList) })
          //   .then((data) => { debugLog(this.dbg, ">>> createCategories() - data " + JSON.stringify(data)); })
          //   .catch((error) => { debugLog(this.dbg, ">>> createCategories() - error " + error); });
          // }

          if (!this.isOnBoarding) {
            this.currentStep = !this.isReadOnly ? '7' : '8';
          } else {
            this.currentStep = '3';
          }

          break;

        case '7':
          let paramsJSON = {
            leadId: this.merchantInfos.leadId,
            country: this.merchantInfos.countryCode,
            contactEmail: this.merchantInfos.email,
            lang: this.lang,
            solution: this.solution,
            promoCode: this.merchantInfos.promoCode,
            scope: this.scope,
            versionId: this.termsAndConditions.tcVersion,
            uniqueKeyId: this.uniqueKeyId,
            isWebOffer: this.isWebOffer,
            version: this.version
          }; // param for Web offers

          debugLog(this.dbg, '>>> Step7 - closeOpportunity() - paramsJSON ' + JSON.stringify(paramsJSON));

          doApexEvent({ operationName: 'closeOpportunity', operationParams: JSON.stringify(paramsJSON) })
            .then((data) => {
              debugLog(this.dbg, '>>> closeOpportunity() - data ' + JSON.stringify(data));
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> closeOpportunity() - error ' + error);
            });
          this.currentStep = '8';
          break;
      }
      this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
      this.stepValidated = false;

      // saveToFile({ merchantInfosJSON: JSON.stringify(this.merchantInfos) })
      //   .then(() => {
      //     debugLog(this.dbg, '>>> saveToFile() - done ');
      //   })
      //   .catch((error) => {
      //     debugLog(this.dbg, '>>> saveToFile() - error ' + error);
      //   });
    }
  }

  handlePrev() {
    let curStep = this.currentStep;
    debugLog(this.dbg, 'handlePrev - curStep = ' + curStep);

    if (curStep == '7') curStep = '2';
    else if (curStep == '6') curStep = !this.isReadOnly ? '5' : '4';
    else if (curStep == '5') curStep = '4';
    else if (curStep == '4') curStep = '3';
    // else if (curStep == "3") curStep = "2";
    else if (curStep == '2') curStep = '1';
    this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
    this.currentStep = curStep;
    debugLog(this.dbg, 'handlePrev - END - this.currentStep = ' + this.currentStep);
  }

  handleCheckEnterpriseNb() {
    debugLog(this.dbg, '>>> handleCheckEnterpriseNb : ' + this.merchantInfos.enterpriseNb);
    this.merchantInfos.enterpriseNb = this.merchantInfos.enterpriseNb.replace(/\s|\./g, ''); //remove dots before processing
    let enterpriseNb = this.merchantInfos.enterpriseNb;
    let email = this.merchantInfos.email;

    if (this.dbg && this.isSandbox) this.isRecaptchaSuccess = true;
    debugLog(this.dbg, '>>> handleCheckEnterpriseNb() - this.isRecaptchaSuccess ' + this.isRecaptchaSuccess);

    let inputFields = [...this.template.querySelectorAll('c-er-portal-input')]; // this kind of assignment is done in order to be able to use .filter() function later
    let checkFields =
      checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && this.validateFieldsFormat(inputFields);

    if (!enterpriseNb || (!isValidEnterpriseNb(enterpriseNb, this.country) && checkFields)) {
      let paramsValues = [];
      paramsValues.push(this.labels.lb_enterprise_nb_format);
      let errMsg = buildTemplate(this.labels.lb_step1_errmsg_enterprise_nb, paramsValues);
      this.showToast(this.labels.lb_error, errMsg, 'error');
    } else if (!this.isRecaptchaSuccess) {
      this.showToast(this.labels.lb_error, this.labels.lb_err_msg_captcha, 'error');
    } else {
      this.showSpinner = true;
      debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- this.showSpinner: ' + this.showSpinner);
      getEnterpriseInfos2({
        enterpriseNb: enterpriseNb,
        country: this.country,
        lang: this.lang,
        uniqueKeyId: this.uniqueKeyId,
        userEmail: this.merchantInfos.email,
        solutionCode: this.solution
      })
        .then((data) => {
          // this.isReadOnly = JSON.parse(data.isReadOnly.toLowerCase());
          debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- data ' + JSON.stringify(data));
          this.ongoingProcess = data.ongoingProcess
            ? JSON.parse(data.ongoingProcess.toLowerCase()) || (data.Activated && data.contractId)
            : false;
          this.activatedContract = data.Activated;
          this.hasContract = data.contractId;

          this.merchantInfos = {};
          this.merchantInfos.enterpriseNb = enterpriseNb;
          this.merchantInfos.storesList = [];
          this.merchantInfos.finCentersList = [];
          this.merchantInfos.usersList = [];
          this.merchantInfos.promoCode = '';
          this.merchantInfos.email = email;

          Object.keys(data).forEach((key) => {
            this.merchantInfos[key] = data[key];
          });

          this.onboardingAccount = this.merchantInfos.Draft; // Show message to redirect onboarding
          if (!this.merchantInfos.badUserEmail) {
            // if(this.onboardingAccount) this.retrieveOnboardingMsg();
            if (this.onboardingAccount) {
              this.retrieveOnboardingDatas();
            } else if (!this.ongoingProcess) {
              debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- getEnterpriseInfos2() - data ' + JSON.stringify(data));
              this.hasCheckedEnterpriseNb = true;
              //TODO to be moved if CRN OK
              this.merchantInfos.hasVATCode = true;
              this.setVATCode();

              // Init picklist with right value
              this.picklistGroup.country = initPicklistValue(this.picklistGroup.country, this.merchantInfos.country); // TODO move this part to Utils as initSelectPicklist() function
              this.picklistGroup.refundCountry = initPicklistValue(
                this.picklistGroup.refundCountry,
                this.merchantInfos.refundCountry
              );
            }
            debugLog(
              this.dbg,
              '>>> handleCheckEnterpriseNb -- this.isReadOnly - activatedContract - onboardingAccount - existingLead: ' +
                this.isReadOnly +
                '-' +
                this.activatedContract +
                '-' +
                this.onboardingAccount +
                '-' +
                this.existingLead
            );
            if (
              !this.isReadOnly &&
              !this.activatedContract &&
              !this.ongoingProcess &&
              !this.onboardingAccount &&
              !this.merchantInfos.existingLead
            ) {
              // Create lead if new merchant
              debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- upsertLead ');
              this.merchantInfos.countryCode = !this.merchantInfos.countryCode
                ? this.country
                : this.merchantInfos.countryCode;
              this.merchantInfos.solution = this.solution;
              this.merchantInfos.scope = this.scope;
              upsertLead({ merchantInfosJSON: JSON.stringify(this.merchantInfos), sourceId: this.sourceId })
                .then((data) => {
                  debugLog(this.dbg, '>>> upsertLead() - data ' + JSON.stringify(data));
                  this.merchantInfos.leadId = data.leadId;
                  this.merchantInfos.keyId = data.keyId;
                  debugLog(this.dbg, '>>> upsertLead() - this.merchantInfos.leadId ' + this.merchantInfos.leadId);
                  debugLog(this.dbg, '>>> upsertLead() - this.merchantInfos.keyId ' + this.merchantInfos.keyId);
                })
                .catch((error) => {
                  debugLog(this.dbg, '>>> upsertLead() - error ' + JSON.stringify(error));
                });
            } else {
              if (!this.onboardingAccount && !this.activatedContract) {
                // Init picklist with right value
                this.picklistGroup.salutation = initPicklistValue(
                  this.picklistGroup.salutation,
                  this.merchantInfos.salutation
                );
                this.picklistGroup.lang = initPicklistValue(this.picklistGroup.lang, this.merchantInfos.lang);
                this.picklistGroup.role = initPicklistValue(this.picklistGroup.role, this.merchantInfos.role);

                if (this.merchantInfos.accountId) {
                  // Get financial center infos if existing account
                  getFinCentersInfos({ accountId: this.merchantInfos.accountId })
                    .then((data) => {
                      debugLog(this.dbg, '>>> getFinCentersInfos() - accountId ' + this.merchantInfos.accountId);
                      debugLog(this.dbg, '>>> getFinCentersInfos() - data ' + JSON.stringify(data));
                      data.forEach((elem, index) => {
                        let finCenter = {};
                        finCenter.noDelete = true; // to hide delete button in data table
                        Object.keys(elem).forEach((key) => {
                          finCenter[key] = elem[key];
                        });
                        finCenter.finCenterId = index + 1;
                        this.merchantInfos.finCentersList.push(finCenter);
                      });
                      if (this.merchantInfos.finCentersList.length > 0) {
                        this.finCenterInfos = JSON.parse(JSON.stringify(this.merchantInfos.finCentersList[0]));
                        this.picklistGroup.refundSalutation = initPicklistValue(
                          this.picklistGroup.refundSalutation,
                          this.finCenterInfos.refundSalutation
                        );
                        this.picklistGroup.refundLang = initPicklistValue(
                          this.picklistGroup.refundLang,
                          this.finCenterInfos.refundLang
                        );
                        this.picklistGroup.refundRole = initPicklistValue(
                          this.picklistGroup.refundRole,
                          this.finCenterInfos.refundRole
                        );
                        this.setRowIndex(this.finCenterInfos, this.merchantInfos.finCentersList, 'finCenterId');
                      }
                      this.currentStep = '2';
                      this.initTermsAndConditions();
                      this.hasCheckedEnterpriseNb = true;
                    })
                    .catch((error) => {
                      debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
                    });
                }
              }
            }

            // Prepare product informations way before moving to page2
            this.handleFinancialConditions();
          }

          this.showSpinner = false;
          debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- this.showSpinner2: ' + this.showSpinner);

          // Unsubscribe from message channel used by recaptcha
          unsubscribe(this.subscription);
          this.subscription = null;
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getEnterpriseInfos2() - error ' + JSON.stringify(error));
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_crn, 'error');
          this.showSpinner = false;
        });
    }
  }

  async handleCheckContractNb() {
    debugLog(this.dbg, '>>> handleCheckContractNb *** START **** contractNb: ' + this.merchantInfos.contractNb);
    if (
      await checkContractNb({
        enterpriseNb: this.merchantInfos.enterpriseNb,
        contractNb: this.merchantInfos.contractNb,
        solutionCode: this.solution
      })
    ) {
      this.contractNbChecked = true;
      this.currentStep = null;
      // this.initCategories();
      debugLog(this.dbg, '>>> handleCheckContractNb() - result OK ');
    } else {
      this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_contract_nb, 'error');
      debugLog(this.dbg, '>>> handleCheckContractNb() - result wrong contract ');
    }
  }

  retrieveOnboardingDatas() {
    debugLog(
      this.dbg,
      '>>> retrieveOnboardingDatas() - this.merchantInfos accountId - contractId: ' +
        this.merchantInfos.accountId +
        ' - ' +
        this.merchantInfos.contractId
    );
    getOnBoardingDatas({ accountId: this.merchantInfos.accountId, contractId: this.merchantInfos.contractId }).then(
      (data) => {
        debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.merchantInfos2 data: ' + JSON.stringify(data));
        Object.assign(this.merchantInfos, data); // merge objects
        this.initCompanyInfos();
        // this.merchantInfos.accountId = data.accountId;
        debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.merchantInfos2 ' + JSON.stringify(this.merchantInfos));

        // Populate data tables with empty records if no data yet (for the display)
        if (!this.hasStore) {
          this.merchantInfos.storesList.push({ name: '', fullAddress: '', finCenterName: '', finCenterId: 1 });
        } else {
          this.merchantInfos.storesList.forEach((store) => {
            if (store.terminalsList && store.terminalsList.length > 0) store.hasTerminal = true;
            store.isWebShop = store.isWebShop == 'true';
            store.physicalTerminalAccepted = store.physicalTerminalAccepted == 'true';
            store.mastercardAccepted = store.mastercardAccepted == 'true';
            store.virtualTerminal = store.virtualTerminal == 'true';
            debugLog(this.dbg, '>>> getOnBoardingDatas() - store ' + JSON.stringify(store));
          });
          debugLog(
            this.dbg,
            '>>> retrieveOnboardingDatas() - this.merchantInfos.storesList[0].chosenCategories ' +
              JSON.stringify(this.merchantInfos.storesList[0].chosenCategories)
          );
        }
        if (!this.hasMerchantUser) {
          this.merchantInfos.usersList = [];
          this.merchantInfos.usersList.push({ userName: '', userEmail: '', contractNb: '', userId: 1 });
          this.merchantUserInfos.userId = 1;
        }
        this.setFinCenterpicklist();
        debugLog(
          this.dbg,
          '>>> retrieveOnboardingDatas() - this.chosenCategories ' + JSON.stringify(this.chosenCategories)
        );
      }
    );
    // .catch((error) => { debugLog(this.dbg, ">>> retrieveOnboardingDatas() - error " + JSON.stringify(error)); });
  }

  initCategories() {
    debugLog(
      this.dbg,
      '>>> () initCategories ***START*** - params ' + this.merchantInfos.countryCode + ' - ' + this.solution
    );
    this.categorieItems = [];
    if (this.chosenCategories.length > 0) this.chosenCategories.forEach((cat) => (previousCatsCsv += cat.id + ','));

    getCategories({
      country: this.merchantInfos.countryCode,
      solution: this.solution,
      existingCatsCsv: previousCatsCsv
    })
      .then((data) => {
        const lang = this.lang.toLowerCase();
        const locale = Object.keys(data).filter((elem) => elem.toLowerCase().includes(lang))[0];
        debugLog(this.dbg, '>>> initCategories() - data: ' + JSON.stringify(data));
        debugLog(this.dbg, '>>> initCategories() - lang: ' + this.lang + ' , locale: ' + locale);
        this.categories = JSON.parse(JSON.stringify(data[locale])); // Dirty hack to prevent from "object is not extensible" exception

        // Do the sort
        let sortedtreeKeys = Object.keys(this.categories).sort();

        sortedtreeKeys.forEach((elem) => {
          this.categories[elem].treeKey = elem; // In order to manage display hide cat in handleToggleCategorie()
          this.categories[elem].showItem = this.categories[elem].level === '1'; //  Show only level 1 Items in the beginning
          this.categories[elem].className =
            this.categories[elem].level === '1' || this.categories[elem].isParent == 'true'
              ? 'categorie-item__parent'
              : 'categorie-item__child';
          this.categories[elem].selectable = this.categories[elem].isParent == 'true' ? false : true;
          this.categories[elem].levelOffset = 'margin-left:' + (this.categories[elem].level - 1) * 10 + '%;'; // Set the margin according to cat level
          if (!this.categories[elem].selectable) this.categories[elem].showChilds = false;

          this.categorieItems.push(this.categories[elem]);
        });

        if (this.merchantInfos.storesList[0].chosenCategories.length > 0) {
          // let initChosenCategories = [];
          this.merchantInfos.storesList[0].chosenCategories.forEach((cat) => {
            debugLog(this.dbg, '>>> initCategories() - cat: ' + JSON.stringify(cat));

            let catFound = false;
            this.categorieItems.forEach((cat2) => {
              if (cat2.id == cat.id && !catFound) {
                cat2.isChecked = cat.isChecked;
                cat2.isMain = cat.isMain;
                catFound = true;
              }
            });

            if (!catFound) {
              // case category from another solution
              this.chosenCategories.push(cat);
            }
          });
        }
        debugLog(this.dbg, '>>> initCategories() - ***END1*** ' + JSON.stringify(this.chosenCategories));
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> initCategories() - error ' + error);
        debugLog(this.dbg, '>>> initCategories() - error str ' + JSON.stringify(error));
      });
    debugLog(this.dbg, '>>> initCategories() - ***END2*** ');
  }

  initCompanyInfos() {
    debugLog(this.dbg, '>>> initCompanyInfos() - ***START***');
    this.companyInfos = [];
    this.companyInfos.push({ [this.labels.lb_step1_enterprise_name]: this.merchantInfos.company });
    this.companyInfos.push({ [this.labels.lb_contract_nb]: this.merchantInfos.contractNumber });
    this.companyInfos.push({ [this.labels.lb_solution_name]: this.merchantInfos.solutionName });
    debugLog(this.dbg, '>>> initCompanyInfos() - ***END000*** this.companyInfos: ' + JSON.stringify(this.companyInfos));
  }

  // generic handler as binding in lwc is one way and to avoid creating one handler per property
  handleMerchantInfos(event) {
    debugLog(this.dbg, 'handleMerchantInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value);
    this.merchantInfos[event.detail.field] = event.detail.value;
    debugLog(this.dbg, 'handleMerchantInfos - new value for the field: ' + this.merchantInfos[event.detail.field]);

    // set picklist to the right option
    if (event.detail.picklist) {
      debugLog(this.dbg, 'handleMerchantInfos is picklist ');
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
      debugLog(this.dbg, 'handleMerchantInfos new picklist: ' + JSON.stringify(this.picklistGroup[event.detail.field]));
    }

    // Check city according to postalCode
    if (
      (event.detail.field === 'postalCode' || event.detail.field === 'city') &&
      this.merchantInfos.postalCode &&
      this.merchantInfos.city
    ) {
      this.checkCity(this.merchantInfos.city, this.merchantInfos.postalCode, this.merchantInfos, 'city');
    }

    debugLog(this.dbg, 'handleMerchantInfos ***END*** ');
  }

  checkCity(city, postalCode, context, cityFieldName) {
    checkCity({ countryCode: this.country, city: city, postalCode: postalCode })
      .then((data) => {
        debugLog(this.dbg, '>>> checkCity() - data ' + data);
        const response = JSON.parse(data);

        if (!response.result) {
          context[cityFieldName] = response.city;
        }
        debugLog(this.dbg, '>>> checkCity() - ***END***');
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> checkCity() - error ' + error);
      });
  }

  handleVATCode(event) {
    this.merchantInfos.hasVATCode = event.detail;
    this.setVATCode();
  }

  setVATCode() {
    //TODO condition to be reviewed for the country check
    if (
      this.merchantInfos.hasVATCode &&
      this.merchantInfos.enterpriseNb &&
      !this.merchantInfos.enterpriseVATCode &&
      (this.merchantInfos.country === 'BELGIUM' || this.country === 'BE')
    ) {
      this.merchantInfos.enterpriseVATCode = 'BE' + this.merchantInfos.enterpriseNb;
      debugLog(this.dbg, 'setVATCode - enterpriseVATCode1 = ' + this.merchantInfos.enterpriseVATCode);
    }

    if (!this.merchantInfos.hasVATCode) this.merchantInfos.enterpriseVATCode = '';
    debugLog(this.dbg, 'setVATCode - enterpriseVATCode2 = ' + this.merchantInfos.enterpriseVATCode);
  }

  handleFinancialConditions() {
    debugLog(
      this.dbg,
      '>>> getFinancialConditions() - params: ' +
        this.country +
        ' - ' +
        this.solution +
        ' - ' +
        this.merchantInfos.promoCode
    );
    this.merchantInfos.countryCode = this.merchantInfos.countryCode || this.country; // Set country code if unset
    getFinancialConditions({
      country: this.merchantInfos.countryCode,
      solution: this.solution,
      promoCode: this.merchantInfos.promoCode,
      scope: this.scope,
      uniqueKeyId: this.uniqueKeyId,
      lang: this.lang
    })
      .then((data) => {
        debugLog(this.dbg, '>>> getFinancialConditions() - datas 1 ' + JSON.stringify(data));

        if (this.merchantInfos.promoCode && data['Error'] && (this.isStepTwo || this.isStepSeven)) {
          // Use Case wrong Promo code
          this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_code, 'error');
        } else if (this.isWebOffer) {
          this.financialConditions = []; // Reinit array

          Object.keys(data).forEach((serviceNb) => {
            let value = data[serviceNb].ER_Percentage__c
              ? data[serviceNb].ER_Percentage__c + '%'
              : data[serviceNb].UnitPrice + '€';
            if (serviceNb == '001') {
              this.financialConditions.push({
                [data[serviceNb].ServiceLabel]: value,
                tooltip: this.labels.lb_step2_msg
              });
            } else {
              this.financialConditions.push({ [data[serviceNb].ServiceLabel]: value });
            }
          });
        } else {
          let admisionFees, licence, participation, mastercardCommission;
          this.financialConditions = []; // Reinit array
          if (!this.merchantInfos.promoCode) {
            // Use Case initial load (no promo code)
            participation = data['001'].ER_Percentage__c + '%';
            admisionFees = data['002']
              ? data['002'].UnitPrice + (data['002'].CurrencyIsoCode === 'EUR' ? '€' : data['002'].CurrencyIsoCode)
              : '0.00€';
            licence = data['003']
              ? data['003'].UnitPrice + (data['003'].CurrencyIsoCode === 'EUR' ? '€' : data['003'].CurrencyIsoCode)
              : '0.00€';
            mastercardCommission = data['017']?.ER_Percentage__c + '%';

            this.financialConditions.push({
              [data['001'].ServiceLabel]: participation,
              tooltip: this.labels.lb_step2_msg
            });
            this.financialConditions.push({ [data['002'].ServiceLabel]: admisionFees });
            this.financialConditions.push({ [data['003'].ServiceLabel]: licence });
            if (mastercardCommission)
              this.financialConditions.push({ [data['017'].ServiceLabel]: mastercardCommission });
          } else {
            // Use Case Promo code
            let contractName, curLine;
            Object.keys(data).forEach((elem) => {
              let discountDetails = ' ';

              debugLog(
                this.dbg,
                '>>> getFinancialConditions() - data[elem].ER_Discount__c ' + data[elem].ER_Discount__c
              );

              if (data[elem].ER_Discount__c > 0) {
                debugLog(this.dbg, '>>> getFinancialConditions() - start build discountDetails ');
                let paramsValues = [];
                paramsValues.push(parseFloat(data[elem].ER_Discount__c).toFixed(2));
                if (data[elem].ER_Offer_validity_end_date__c)
                  paramsValues.push(data[elem].ER_Offer_validity_end_date__c);
                debugLog(this.dbg, '>>> getFinancialConditions() - paramsValues ' + JSON.stringify(paramsValues));
                debugLog(
                  this.dbg,
                  '>>> getFinancialConditions() - this.labels.lb_discount_infos ' + this.labels.lb_discount_infos
                );
                discountDetails += buildTemplate(this.labels.lb_discount_infos, paramsValues);
                if (!data[elem].ER_Offer_validity_end_date__c) {
                  // Case no end date, remove text saying "until ..."
                  let validityText = discountDetails.substring(
                    discountDetails.indexOf('%') + 1,
                    discountDetails.length - 1
                  );
                  discountDetails = discountDetails.replace(validityText, '');
                }
              }
              debugLog(this.dbg, '>>> getFinancialConditions() - discountDetails ' + discountDetails);

              switch (elem) {
                case 'ContractName':
                  contractName = data['ContractName'].ContractName;
                  break;
                case '001':
                  participation = data['001'].ER_Percentage__c + '%' + discountDetails;
                  this.financialConditions[2] = {
                    [data['001'].ServiceLabel]: participation,
                    tooltip: this.labels.lb_step2_msg
                  };
                  break;
                case '002':
                  //TODO Manage multi currencies (code and symbol)
                  admisionFees =
                    data['002'].UnitPrice +
                    (data['002'].CurrencyIsoCode === 'EUR' ? '€' : data['002'].CurrencyIsoCode) +
                    discountDetails;
                  this.financialConditions[0] = { [data['002'].ServiceLabel]: admisionFees };
                  break;
                case '003':
                  licence =
                    data['003'].UnitPrice +
                    (data['003'].CurrencyIsoCode === 'EUR' ? '€' : data['003'].CurrencyIsoCode) +
                    discountDetails;
                  this.financialConditions[1] = { [data['003'].ServiceLabel]: licence };
                  break;
                case '017':
                  mastercardCommission = data['017'].ER_Percentage__c + '%' + discountDetails;
                  this.financialConditions[3] = { [data['017'].ServiceLabel]: mastercardCommission };
                  break;
              }
            });
            debugLog(
              this.dbg,
              '>>> getFinancialConditions() - financialConditions before ctr ' +
                JSON.stringify(this.financialConditions)
            );

            if (contractName) this.financialConditions.splice(0, 0, { [this.labels.lb_step2_contract]: contractName });
            debugLog(
              this.dbg,
              '>>> getFinancialConditions() - financialConditions after ctr ' + JSON.stringify(this.financialConditions)
            );

            if (this.isStepTwo || this.isStepSeven)
              this.showToast(this.labels.lb_success, this.labels.lb_msg_update_success, 'success');

            this.updateOpportunity();
          }
          debugLog(
            this.dbg,
            '>>> getFinancialConditions() - financialConditions' + JSON.stringify(this.financialConditions)
          );
        }
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getFinancialConditions() - error ' + JSON.stringify(error));
      });
  }

  validateStep() {
    debugLog(this.dbg, 'validateStep - Start ');
    if (this.isReadOnly) {
      this.stepValidated = true;
    } else {
      // Get input and picklist fields
      let inputFields = [...this.template.querySelectorAll('c-er-portal-input')]; // this kind of assignment is done in order to be able to use .filter() function later

      this.stepValidated = this.checkDataQty(); // Check if items have already been created (it allows to go next step if one item saved even if user is starting to fill a new item)

      if (this.stepValidated) {
        let checkFormats, requiredFields;
        switch (this.currentStep) {
          case '1':
            debugLog(this.dbg, 'validateStep - step1 ');
            // Check required fields in the 1st step
            let pkListFields = this.template.querySelectorAll('c-er-portal-picklist');

            requiredFields =
              checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) &&
              checkRequiredFields(pkListFields, this.labels.lb_err_msg_required_field);
            debugLog(this.dbg, 'validateStep - required fields: ' + this.stepValidated);
            // to check if one of those fields "Contact phone" or "mobile" is populated
            let checkMobileOrPhone;
            let mobileOrPhoneFields = [];
            mobileOrPhoneFields = inputFields.filter(
              (elem) => elem.propertyName === 'contactPhone' || elem.propertyName === 'mobile'
            );

            if (mobileOrPhoneFields[0].value || mobileOrPhoneFields[1].value) {
              debugLog(this.dbg, 'validateStep - mobileOrPhoneFields OK');
              checkMobileOrPhone = true;
              mobileOrPhoneFields[0].hasError = false;
              mobileOrPhoneFields[0].errorMessage = '';
            } else {
              debugLog(this.dbg, 'validateStep - mobileOrPhoneFields error');
              checkMobileOrPhone = false;
              mobileOrPhoneFields[0].hasError = true;
              mobileOrPhoneFields[0].errorMessage = this.labels.lb_err_msg_required_field;
            }

            // check email, gsm or tel, regex tel
            checkFormats = this.validateFieldsFormat(inputFields);
            this.stepValidated = checkFormats && checkMobileOrPhone && requiredFields;
            debugLog(this.dbg, 'validateStep (1) - this.stepValidated = ' + this.stepValidated);
            break;
          case '2':
            // check IBAN & promo inside component (not here)
            if (
              (this.isWebOffer || this.ongoingProcess) &&
              ((this.finCenterInfos &&
              this.finCenterInfos.iban?.includes('********')) || 
              this.merchantInfos.finCentersList.length > 0)
            )
              this.isValidIBAN = true; // escape IBAN check if in web offer context & anonimized
            if (!this.isValidIBAN) {
              this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, 'error');
            }

            // check email, gsm or tel, regex tel
            checkFormats = this.validateFieldsFormat(inputFields);
            this.stepValidated = this.isValidIBAN && checkFormats;

            //check all fin centers
            if (this.stepValidated) {
              this.merchantInfos.finCentersList.forEach((fc) => {
                if (this.stepValidated && (!fc.contact?.trim() || !fc.iban?.trim())) {
                  this.stepValidated = false;
                  let errMsg = buildTemplate(this.labels.lb_err_msg_complete_fc, [fc.name]);
                  this.showToast(this.labels.lb_error, errMsg, 'error');
                }
              });
            }

            break;
        }
      }
    }
    debugLog(this.dbg, 'validateStep - finish: ' + this.stepValidated);
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
        case 'enterpriseVATCode':
          // add specific modulo check for VAT LU
          if (this.merchantInfos.countryCode == 'LU') {
            otherChecks = this.checkLuVATModulo(field);
            field.hasError = !otherChecks;
          }
          //For BE and LU, the check has to be done only if VAT number starts with country code
          if (field.value.startsWith(this.merchantInfos.countryCode))
            fieldValidationList.push({
              field: field,
              regex: this.labels.regex_vat,
              errMsg: this.labels.lb_err_msg_vat_format
            });
          debugLog(this.dbg, 'validateFieldsFormat otherChecks: ' + otherChecks);

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

  checkLuVATModulo(vatField) {
    debugLog(this.dbg, 'checkLuVATModulo *** START *** vatField.value: ' + vatField.value);

    let result = true;
    if (vatField.value.startsWith('LU')) {
      debugLog(
        this.dbg,
        'checkLuVATModulo is LU - next check result = ' +
          (vatField.value.substring(2, 8) % 89 != vatField.value.substring(8, 10))
      );
      result = vatField.value.substring(2, 8) % 89 == vatField.value.substring(8, 10);
    }
    debugLog(this.dbg, 'checkLuVATModulo vatField ' + JSON.stringify(vatField));
    debugLog(this.dbg, 'checkLuVATModulo result ' + result);
    return result;
  }

  checkDataQty() {
    debugLog(this.dbg, 'checkDataQty *** START *** ');
    let isQtyOK = false;
    // Check if sufficient datas have been filled according to current step
    switch (this.currentStep) {
      case '2': // Fin centers, at least 1
        isQtyOK = this.merchantInfos.finCentersList.length > 0;
        if (!isQtyOK) this.showToast(this.labels.lb_error, this.labels.lb_step2_errmsg_nb_fincenter, 'error');
        break;
      case '1': //TODO temporary bypass
      case '7': //TODO temporary bypass
        isQtyOK = true;
        break;
    }
    debugLog(this.dbg, 'checkDataQty - isQtyOK = ' + isQtyOK + ' for step ' + this.currentStep);
    return isQtyOK;
  }

  handlePromoCode(event) {
    this.hasPromoCode = event.detail;
    debugLog(this.dbg, 'handlePromoCode - hasPromoCode = ' + this.hasPromoCode);
  }

  handlehasNoBillingAccount(event) {
    this.hasNoBillingAccount = event.detail == 'true';
  }

  updateOpportunity() {
    doApexEvent({
      operationName: 'updateOpportunity',
      operationParams:
        this.merchantInfos.leadId + '|' + this.merchantInfos.promoCode + '|' + this.solution + '|' + this.scope
    })
      .then((data) => {
        debugLog(this.dbg, '>>> updateOpportunity() - data ' + JSON.stringify(data));
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> updateOpportunity() - error ' + error);
      });
  }

  handleSameAsMainContact(event) {
    debugLog(this.dbg, 'handleSameAsMainContact event.detail = ' + event.detail);

    const fieldMapping = {
      refundContactId: 'contactId',
      refundSalutation: 'salutation',
      refundFirstName: 'firstName',
      refundLastName: 'lastName',
      refundLang: 'lang',
      refundContactPhone: 'contactPhone',
      refundMobile: 'mobile',
      refundRole: 'role',
      refundEmail: 'email',
      refundFax: 'fax'
    };
    let fieldList = this.template.querySelectorAll('[data-group="refundContact"]');
    debugLog(this.dbg, 'handleSameAsMainContact - fieldList length = ' + fieldList.length);

    if (event.detail) {
      //If checkbox is checked
      debugLog(this.dbg, 'handleSameAsMainContact finCenterInfos = ' + JSON.stringify(this.finCenterInfos));
      initFields(fieldList, this.merchantInfos, true, fieldMapping, this.finCenterInfos);
      // Set picklists
      this.picklistGroup.refundSalutation = JSON.parse(JSON.stringify(this.picklistGroup.salutation));
      this.picklistGroup.refundLang = JSON.parse(JSON.stringify(this.picklistGroup.lang));
      this.picklistGroup.refundRole = JSON.parse(JSON.stringify(this.picklistGroup.role));
      debugLog(
        this.dbg,
        'handleSameAsMainContact this.picklistGroup.refundSalutation ' +
          JSON.stringify(this.picklistGroup.refundSalutation)
      );
    } else {
      eraseFieldsAndEnable(fieldList);
      // unselect picklists
      resetPicklist([
        this.picklistGroup.refundSalutation,
        this.picklistGroup.refundLang,
        this.picklistGroup.refundRole
      ]);
    }
    this.savFinCenterBtnDisabled = false;
    debugLog(this.dbg, 'handleSameAsMainContact END ');
  }

  handleCopyMainAddress(event) {
    debugLog(this.dbg, 'handleCopyMainAddress ***Start*** ');
    const fieldMapping = {
      refundAddress: 'address',
      refundPostalCode: 'postalCode',
      refundCity: 'city',
      refundCountry: 'country'
    };
    let fieldList = this.template.querySelectorAll('[data-group="refundAddress"]');
    if (event.detail) {
      //If checkbox is checked
      initFields(fieldList, this.merchantInfos, true, fieldMapping, this.finCenterInfos);
      this.picklistGroup.refundCountry = JSON.parse(JSON.stringify(this.picklistGroup.country));
    } else {
      eraseFieldsAndEnable(fieldList);
      resetPicklist([this.picklistGroup.refundCountry]);
    }
    this.savFinCenterBtnDisabled = false;
    debugLog(this.dbg, 'handleCopyMainAddress ***END*** ');
  }

  handleFinCenterInfos(event) {
    //TODO voir si factorisable?
    debugLog(this.dbg, 'handleFinCenterInfos ***Start*** ');
    debugLog(this.dbg, 'handleFinCenterInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value);
    this.finCenterInfos[event.detail.field] = event.detail.value;

    // set picklist to the right option
    if (event.detail.picklist) {
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
      debugLog(
        this.dbg,
        'handleFinCenterInfos new picklist value: ' + JSON.stringify(this.picklistGroup[event.detail.field])
      );
    }

    // Check IBAN
    if (event.detail.field.startsWith('iban')) {
      debugLog(this.dbg, '>>> getBIC() - this.finCenterInfos iban ' + this.finCenterInfos[event.detail.field]);
      this.finCenterInfos.bankAccountSFId = ''; // In order to create a new bank account (webform offer process)
      if (
        this.finCenterInfos[event.detail.field] &&
        this.finCenterInfos[event.detail.field].trim().substring(0, 2).toUpperCase() != this.merchantInfos.countryCode
      ) {
        debugLog(this.dbg, '>>> getBIC() - error  country different ');
        this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban_country, 'error');
        this.isValidIBAN = false;
        this.finCenterInfos[event.detail.field] = '';
      } else {
        let accountType = event.detail.field == 'ibanBilling' ? 'Billing' : '';
        this.checkBankAccount(this.finCenterInfos[event.detail.field], accountType);
      }
      debugLog(this.dbg, 'handleFinCenterInfos -- this.isValidIBAN: ' + this.isValidIBAN);
    }

    // Check city according to postalCode
    if (
      (event.detail.field === 'refundPostalCode' || event.detail.field === 'refundCity') &&
      this.finCenterInfos.refundPostalCode &&
      this.finCenterInfos.refundCity
    ) {
      this.checkCity(
        this.finCenterInfos.refundCity,
        this.finCenterInfos.refundPostalCode,
        this.finCenterInfos,
        'refundCity'
      );
    }

    this.savFinCenterBtnDisabled = false;
    debugLog(this.dbg, 'handleFinCenterInfos ***END*** ');
  }

  async checkBankAccount(ibanNb, accountType) {
    debugLog(this.dbg, '>>> checkBankAccount() - check iban ' + ibanNb + ' -> ' + accountType);
    if (ibanNb) {
      await getBIC({ iban: ibanNb.trim() })
        .then((data) => {
          debugLog(this.dbg, '>>> getBIC() - data ' + data);
          const response = JSON.parse(data);
          this.isValidIBAN = response.valid;
          if (this.isValidIBAN) {
            if (accountType != 'Billing') accountType = '';
            this.finCenterInfos['bic' + accountType] = this.checkIBAN = response.bankData.bic;
            this.finCenterInfos['bankName' + accountType] = response.bankData.name;
          } else {
            this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, 'error');
          }
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getBIC() - error ' + error);
        });
    }
    debugLog(this.dbg, 'checkBankAccount ***END*** ');
  }

  async saveFinCenter(event) {
    debugLog(this.dbg, 'saveFinCenter ***START*** ');
    let finCenter = this.finCenterInfos;
    debugLog(this.dbg, 'saveFinCenter -- this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));
    debugLog(
      this.dbg,
      'saveFinCenter -- (this.merchantInfos.finCentersList.length + 1): ' +
        (this.merchantInfos.finCentersList.length + 1)
    );

    if (finCenter.iban && finCenter.iban.includes('*')) this.isValidIBAN = true; // Set IBAN to valid if anonymized (it won't be modified in SF then)

    // if(!this.isValidIBAN) this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, "error");
    if (!this.isValidIBAN) await this.checkBankAccount(finCenter.iban, ''); // Do one more check in order to cover one specific use case
    if (finCenter.ibanBilling) await this.checkBankAccount(finCenter.ibanBilling, 'Billing');

    let checkFields = checkRequiredFields(
      this.template.querySelectorAll('[data-group^="refund"]'),
      this.labels.lb_err_msg_required_field
    );
    if (this.isValidIBAN && checkFields) {
      debugLog(this.dbg, 'saveFinCenter -- finCenter.name: ' + finCenter.name);
      let finCenterNum = !finCenter.finCenterId ? this.getFinCenterId() : finCenter.finCenterId;
      finCenter.name = finCenter.name
        ? finCenter.name.trim()
        : this.merchantInfos.legalName + ' (' + finCenterNum + ')';
      debugLog(this.dbg, 'saveFinCenter -- finCenter.name2: ' + finCenter.name);
      finCenter.contact = finCenter.refundFirstName + ' ' + finCenter.refundLastName;
      finCenter.fullAddress = finCenter.refundAddress + ', ' + finCenter.refundPostalCode + ' ' + finCenter.refundCity;

      debugLog(this.dbg, 'saveFinCenter -- this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));

      // Reorder finCenter columns to adjust datatable display
      let finCenterReorderedCols = {
        name: finCenter.name,
        contact: finCenter.contact,
        fullAddress: finCenter.fullAddress,
        iban: finCenter.iban.toUpperCase().replace(/\s|\./g, ''),
        bic: finCenter.bic,
        bankName: finCenter.bankName,
        ibanBilling: finCenter.ibanBilling?.toUpperCase().replace(/\s|\./g, ''),
        bicBilling: finCenter.bicBilling,
        bankNameBilling: finCenter.bankNameBilling,
        countryCode: this.country,
        refundContactId: finCenter.refundContactId,
        refundSalutation: finCenter.refundSalutation,
        refundFirstName: finCenter.refundFirstName,
        refundLastName: finCenter.refundLastName,
        refundLang: finCenter.refundLang,
        refundContactPhone: finCenter.refundContactPhone,
        refundMobile: finCenter.refundMobile,
        refundRole: finCenter.refundRole,
        refundEmail: finCenter.refundEmail,
        refundFax: finCenter.refundFax,
        refundAddress: finCenter.refundAddress,
        refundPostalCode: finCenter.refundPostalCode,
        refundCity: finCenter.refundCity,
        refundCountry: finCenter.refundCountry,
        finCenterId: finCenter.finCenterId,
        rowIndex: finCenter.rowIndex,
        finCenterSFId: finCenter.finCenterSFId,
        finCenterAccountSFId: finCenter.finCenterAccountSFId,
        bankAccountSFId: finCenter.bankAccountSFId
      };

      finCenter = finCenterReorderedCols;
      if (finCenter.finCenterSFId) finCenter.noDelete = true; // to hide delete button in data table

      debugLog(this.dbg, 'saveFinCenter -- before ins or upd: finCenter.finCenterId =  ' + finCenter.finCenterId);
      if (finCenter.finCenterId) {
        // case existing fin center, then update
        debugLog(this.dbg, 'saveFinCenter Update');

        const finCenterIndex = this.merchantInfos.finCentersList.findIndex(
          (fc) => fc.finCenterId === finCenter.finCenterId
        );
        this.merchantInfos.finCentersList.splice(finCenterIndex, 1, finCenter);
      } else {
        // case new fin center, then insert
        debugLog(this.dbg, 'saveFinCenter Insert');

        //Set finCenterId
        finCenter.finCenterId = this.getFinCenterId();
        debugLog(this.dbg, 'saveFinCenter -- before ins: finCenter.finCenterId =  ' + finCenter.finCenterId);

        this.merchantInfos.finCentersList.push(JSON.parse(JSON.stringify(finCenter)));
        this.finCenterInfos = JSON.parse(JSON.stringify(finCenter));
        this.setRowIndex(this.finCenterInfos, this.merchantInfos.finCentersList, 'finCenterId');
        debugLog(this.dbg, 'saveFinCenter Insert done  ');
      }
      this.setFinCenterpicklist();
      this.showToast(this.labels.lb_success, this.labels.lb_msg_update_success, 'success');
      this.savFinCenterBtnDisabled = true;
      this.template.querySelector('[data-id="finCentersList"]').scrollIntoView();
      this.showFinCenterdetails = false;
    }

    debugLog(this.dbg, 'saveFinCenter  -- ***END***');
  }

  // TODO factorisable: getItemId(objList)
  getFinCenterId() {
    let finCenterIdList = this.merchantInfos.finCentersList.map((finCenter) => finCenter.finCenterId);
    return finCenterIdList.length === 0 ? 1 : Math.max(...finCenterIdList) + 1;
  }

  setFinCenterpicklist() {
    if (this.hasMultipleFinCenter) {
      this.picklistGroup.finCenterId = [{ key: '', value: '...', hidden: true }];
      this.merchantInfos.finCentersList.forEach((elem) =>
        this.picklistGroup.finCenterId.push({ key: elem.finCenterId, value: elem.name })
      );
    }
    debugLog(
      this.dbg,
      'setFinCenterpicklist -- this.picklistGroup.finCenterId = ' + JSON.stringify(this.picklistGroup.finCenterId)
    );
  }

  newFinCenter() {
    debugLog(this.dbg, 'newFinCenter - START');
    this.showFinCenterdetails = true;
    this.finCenterInfos = {};
    let finCenter = this.finCenterInfos; // finCenter & pkList are alias to make code less verbose
    let pkList = this.picklistGroup;

    this.template.querySelectorAll('[data-group="refundCbx"]').forEach((cb) => (cb.isChecked = false));
    eraseFieldsAndEnable(this.template.querySelectorAll('[data-group="refundAddress"], [data-group="refundContact"]'));
    resetPicklist([pkList.refundSalutation, pkList.refundLang, pkList.refundRole, pkList.refundCountry]);

    finCenter.refundSalutation = finCenter.refundLang = finCenter.refundRole = finCenter.refundCountry = '';
    debugLog(this.dbg, 'newFinCenter - before scrollIntoView');
    this.template.querySelector('[data-id="ibanTitle"]').scrollIntoView();
    debugLog(this.dbg, 'newFinCenter - END');
  }

  handleEditFinCenter(event) {
    debugLog(this.dbg, 'handleEditFinCenter - ***Start*** ');
    this.isReadOnlyEditable = false;
    this.showFinCenterdetails = true;

    let fieldList = this.template.querySelectorAll(
      '[data-group="refundAddress"], [data-group="refundContact"], [data-id="iban"]'
    );
    let finCentersList = this.merchantInfos.finCentersList;

    debugLog(
      this.dbg,
      'handleEditFinCenter - Row to be displayed: ' + JSON.stringify(finCentersList[event.detail.value])
    );
    initFields(fieldList, finCentersList[event.detail.value], this.isReadOnly, null, this.finCenterInfos);

    // Init non displayed field
    this.finCenterInfos.rowIndex = event.detail.value;
    this.finCenterInfos.finCenterId = event.detail.value + 1;
    this.finCenterInfos.name = finCentersList[event.detail.value].name;
    this.finCenterInfos.finCenterSFId = finCentersList[event.detail.value].finCenterSFId;
    this.finCenterInfos.finCenterAccountSFId = finCentersList[event.detail.value].finCenterAccountSFId;
    this.finCenterInfos.bankAccountSFId = finCentersList[event.detail.value].bankAccountSFId;
    debugLog(this.dbg, 'handleEditFinCenter - this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));

    // Set picklists displayed values
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist'));

    debugLog(this.dbg, 'handleEditFinCenter *** END *** ');
  }

  handleDeleteFinCenter(event) {
    this.merchantInfos.finCentersList.splice(event.detail.value, 1);
    this.template.querySelectorAll('[data-group="refundCbx"]').forEach((cb) => (cb.isChecked = false));
    this.setRowIndex(this.finCenterInfos, this.merchantInfos.finCentersList, 'finCenterId');
    this.newFinCenter();
    this.setFinCenterpicklist();
  }

  setRowIndex(curRecord, recTable, recIdName) {
    recTable.forEach((row, index) => (row.rowIndex = index));
    debugLog(this.dbg, 'setRowIndex -- recTable: ' + JSON.stringify(recTable));

    debugLog(this.dbg, 'setRowIndex -- recIdName: ' + recIdName);
    debugLog(this.dbg, 'setRowIndex -- curRecord[recIdName]: ' + curRecord[recIdName]);
    if (curRecord[recIdName])
      recTable.forEach((row, index) => {
        if (row[recIdName] === curRecord[recIdName]) curRecord.rowIndex = index;
      });
    debugLog(this.dbg, 'setRowIndex -- curRecord.rowIndex: ' + JSON.stringify(curRecord.rowIndex));
  }

  initTermsAndConditions() {
    debugLog(this.dbg, '>>> initTermsAndConditions() - lang ' + this.lang);
    getTermsAndConditions({
      country: this.merchantInfos.countryCode,
      lang: this.lang,
      solution: this.solution,
      scope: this.scope
    })
      .then((data) => {
        debugLog(this.dbg, '>>> initTermsAndConditions() - data ' + JSON.stringify(data));
        debugLog(this.dbg, '>>> initTermsAndConditions() - version ' + data.tcVersion);
        this.termsAndConditions = data;
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> initTermsAndConditions() - error ' + error);
      });
  }

  handleAcceptConditions(event) {
    this.hasAcceptedConditions = event.detail;
    debugLog(this.dbg, 'handleAcceptConditions - hasAcceptedConditions = ' + this.hasAcceptedConditions);
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
    const event = new ShowToastEvent({ title: title, message: message, variant: variant });
    this.dispatchEvent(event);
  }

  redirectWithoutKeyParameter() {
    console.log('redirection code to be removed');
    var parameter = 'key';
    var url = document.location.href;
    var urlparts = url.split('?');

    if (urlparts.length >= 2) {
      var urlBase = urlparts.shift();
      var queryString = urlparts.join('?');
      var prefix = encodeURIComponent(parameter) + '=';
      var pars = queryString.split(/[&;]/g);
      for (var i = pars.length; i-- > 0; ) if (pars[i].lastIndexOf(prefix, 0) !== -1) pars.splice(i, 1);
      url = urlBase + '?' + pars.join('&');
      window.location.href = url;
    }
    return url;
  }
}