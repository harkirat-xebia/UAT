/*************************************************************************************
LWC Name:     ErPortalContractingFlow
Version:      1.0
Created Date: 20/12/2022
Purpose:      Main component for auto enrollment (client & merchant).

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           20/12/2022  Initial (Auto enrollment contracting for core (except BE))
* SLI           27/04/2023  Add My settlement information step
* HD            09/05/2023  Add Cross Selling (COUL-1743)
*************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

// Apex methods
import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getCompanyInfosCore from '@salesforce/apex/GenericWithoutSharing.getCompanyInfosCore';
import upsertLeadCore from '@salesforce/apex/GenericWithoutSharing.upsertLeadCore';
import getProductListNames from '@salesforce/apex/GenericWithoutSharing.getProductListNames';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';

import checkContractNb from '@salesforce/apex/GenericWithoutSharing.checkContractNb';
import checkCity from '@salesforce/apex/APER30_AutoEnrollment_Management.checkCity';
import getFinancialConditions from '@salesforce/apex/GenericWithoutSharing.getFinancialConditions';
import getBIC from '@salesforce/apex/APER30_AutoEnrollment_Management.getBIC';
import upsertLead from '@salesforce/apex/APER30_AutoEnrollment_Management.upsertLead';
import getTermsAndConditions from '@salesforce/apex/APER30_AutoEnrollment_Management.getTermsAndConditions';
import updateAccount from '@salesforce/apex/GenericWithoutSharing.updateAccount';
import getFinCentersInfos from '@salesforce/apex/GenericWithoutSharing.getFinCentersInfos';
import saveToFile from '@salesforce/apex/GenericWithoutSharing.saveToFile';
import getOnBoardingDatas from '@salesforce/apex/GenericWithoutSharing.getOnBoardingDatas';
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
import encrypt from '@salesforce/apex/GenericWithoutSharing.encrypt';
import getAccountIdFromCRN from '@salesforce/apex/GenericWithoutSharing.getAccountIdFromCRN';

// import getAcceptorModels from "@salesforce/apex/APER30_AutoEnrollment_Management.getAcceptorModels";
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
  debugLog,
  buildTemplate
} from 'c/erPortalUtils';
import { setProductListNew } from 'c/erPortalBusinessRules';

export default class ErPortalContractingFlow extends LightningElement {
  currentPageReference = null;
  urlStateParameters = null;

  @api country; // Parameter to be set in the builder for the page variation dedicated to the country
  @api lang; // Lang parameter get from url
  @api locale; // Locale parameter get from url
  @api solution; // Product parameter get from url
  @api sourceId; // sourceId to link company to a particular campaign
  @api uniqueKeyId; // Unique Key ID for Webform offer and Auto enrollment v2 Onboarding
  @api version; // used to detect if Auto enrollment v2
  @api dbg; // Debug mode (to enable logs display)
  // @api isFromWebOffer; // Parameter added when url is from quote web offer
  @api scope; // scope parameter get from url
  @api cs; // cross selling
  currentStep = '1';
  stepValidated;

  subscription = null; // used for recaptcha component
  isRecaptchaSuccess;
  @wire(MessageContext)
  messageContext;

  showSpinner;
  isReadOnly;
  isReadOnlyEditable;
  hasCheckedEnterpriseNb;
  existingAccount;
  activatedAccount;
  hasContract;
  expiredQuote;
  ongoingOpp;
  existingClient;
  existingMerchantStore;
  showWelcomeMsg;
  onboardingAccount;
  contractNbChecked;
  isConvertedLead;
  disableCheckCompanyBtn = true;
  acceptTermsPrice;
  @track productList = [];
  additionalProducts;
  erfiCardType;
  erfiBenefits;
  invalidScope;
  invalidProduct;
  activeProduct;
  selectedProduct;
  additionalSelectedProducts = [];
  // productList = [{labels:{cardName:"Edenred Transports", }, isMain:true, optionsList:[{optionName: "Virtual Card", optionText:"Virtual Card"},{optionName: "CardType", optionText:"How do you want to use the benefits ?", choice1:"Virtual Card", choice2:"Physical Card"},{optionName: "Benefits", optionText:"Which benefits do you want to order ?", choice1:"Lunch & Virike", choice2:"Lunch"}]}];

  // Labels for fields, format patterns, error messages
  @track labels = {};
  labelsAllLangs = {};
  isSandbox;

  // Picklist values
  @track picklistGroup = {};
  @track companyInfos = {};

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
  //   @track merchantUsersListTableColumns = {};
  @track terminalsListTableColumns = {};

  //   @track merchantUserInfos = {};
  @track storeInfos = {};
  terminalProvidersAndModels = {};

  // Store categories (Dependant values)
  @track categories = {};
  @track categorieItems = [];
  @track chosenCategories = [];

  // Terms & conditions
  @track termsAndConditions = {};

  hasAcceptedConditions;

  //   @track companyInfos = [];
  // onboardingEndMessage = '';
  isStepUsers;

  stepsCount = 0;
  showHeader = false;

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
    this.scope = this.urlStateParameters.scope;
    this.dbg = this.urlStateParameters.dbg === 'true' ? true : false;
    this.companyInfos.enterpriseNb = this.urlStateParameters.crn;

    this.locale = this.urlStateParameters.language;
    this.uniqueKeyId = this.urlStateParameters.key;
    if (!this.uniqueKeyId && !this.companyInfos.enterpriseNb) this.showWelcomeMsg = true;
    this.cs = this.urlStateParameters.cs === 'true' ? true : false;
    this.selectedProduct = this.solution;
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
      pkGrp.invoicingMethod =
        [];

    this.subscribeToMessageChannel(); // Subscribe to recaptcha message service

    if (this.cs) {
      // When cross selling no captcha is displayed
      this.isRecaptchaSuccess = true;
    }

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

        if (this.companyInfos.enterpriseNb) {
          this.handleCheckEnterpriseNb();
        }

        // if ((this.isWebOffer || this.isOnBoarding) && this.uniqueKeyId) {
        //   // Web offer or on boarding use case
        //   debugLog(this.dbg, '>>> connectedCallback() - *** Start getEnterpriseInfos *** ');

        //   getEnterpriseInfos({
        //     enterpriseNb: null,
        //     country: this.country,
        //     lang: this.lang,
        //     uniqueKeyId: this.uniqueKeyId,
        //     userEmail: null,
        //     solutionCode: this.solution
        //   })
        //     .then((data) => {
        //       debugLog(this.dbg, '>>> getEnterpriseInfos() - data ' + JSON.stringify(data));
        //       this.companyInfos = {};
        //       this.companyInfos.storesList = [];
        //       this.companyInfos.finCentersList = [];

        //       Object.keys(data).forEach((key) => {
        //         this.companyInfos[key] = data[key];
        //       });

        //       this.activatedAccount = this.companyInfos.Activated; // Show message already have active contract for weboffer
        //       this.hasContract = this.companyInfos.contractId;
        //       debugLog(this.dbg, '>>> getEnterpriseInfos() - this.activatedAccount ' + this.activatedAccount);

        //       if (!this.activatedAccount) {
        //         this.showWelcomeMsg = true;
        //         this.hasCheckedEnterpriseNb = true;

        //         // Init picklist with right value
        //         pkGrp.country = initPicklistValue(
        //           JSON.parse(JSON.stringify(pkGrp.country)),
        //           this.companyInfos.country
        //         ); // TODO move this part to Utils as initSelectPicklist() function
        //         // pkGrp.refundCountry = initPicklistValue(pkGrp.refundCountry, this.companyInfos.refundCountry);
        //         // pkGrp.storeCountry = initPicklistValue(pkGrp.storeCountry, this.companyInfos.storeCountry);

        //         // // Init picklist with right value
        //         // pkGrp.salutation = initPicklistValue(pkGrp.salutation, this.companyInfos.salutation);
        //         // pkGrp.lang = initPicklistValue(pkGrp.lang, this.companyInfos.lang);
        //         // pkGrp.role = initPicklistValue(pkGrp.role, this.companyInfos.role);

        //         // if (!this.isOnBoarding) {
        //         //   this.handleFinancialConditions();
        //         //   this.hasPromoCode = this.uniqueKeyId && this.companyInfos.promoCode; // Show promocode in weboffer if available
        //         // }

        //       }

        //       // if (this.isOnBoarding) {
        //       //   this.retrieveOnboardingDatas();
        //       //   this.currentStep = null;
        //       // }
        //     })
        //     .catch((error) => {
        //       this.expiredQuote = true;
        //       this.showSpinner = false;
        //       debugLog(this.dbg, '>>> getEnterpriseInfos()1 - error ' + JSON.stringify(error));
        //     });
        // }

        debugLog(true, '>>> connectedCallback() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getLabels() - error ' + error);
      });
  }

  // Initialise all the number of steps and their respective name
  get stepList() {
    if (this.labels.lb_steps_contracting != null) {
      let steps = [];
      let stepCounter = 0;
      this.stepsCount = this.labels.lb_steps_contracting.split('|').length;
      this.labels.lb_steps_contracting.split('|').forEach((step, index) => {
        stepCounter++;
        steps.push({ nb: stepCounter.toString(), label: step });
      });
      return steps;
    } else {
      return [{ nb: '1', label: ' ' }];
    }
  }

  get phase() {
    if (this.stepList != null) {
      let phaseTable = {};
      for (let i = 1; i <= this.stepList.length; i++) {
        phaseTable[i] = i.toString();
      }
      return phaseTable[this.currentStep];
    }
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
    return this.currentStep === '3' && this.currentStep !== this.stepsCount.toString();
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
  get isSummary() {
    return this.currentStep === this.stepsCount.toString();
  }
  get isEndPage() {
    return this.currentStep === '8';
  }
  get isShowHeader() {
    return this.showHeader && !this.isEndPage && !this.cs && !this.existingClient && !this.existingMerchantStore; // SLI 3443
  }

  get isMerchant() {
    return this.scope == 'M';
  }

  get isERFI() {
    return this.country != null && this.country.toUpperCase() === 'FI';
  }

  get isEnableNext() {
    debugLog(true, '>>> isEnableNext() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);

    return (
      this.hasCheckedEnterpriseNb &&
      ['1', '2', '3'].includes(this.currentStep) &&
      this.currentStep != this.stepsCount.toString()
      //   (!this.activatedAccount || !this.hasContract) &&
      //   !this.expiredQuote && !this.ongoingOpp && !this.existingClient &&
      //   ((!['3', '7', '8'].includes(this.currentStep) && !this.isReadOnly) ||
      //     (!['3', '6', '8'].includes(this.currentStep) && this.isReadOnly))) ||
      // (this.isOnBoarding && ['2', '8'].includes(this.currentStep))
    );
    // !this.isOnBoarding;
  }

  get isEnablePrev() {
    // return this.currentStep != '1' && this.currentStep != '2' && this.currentStep != '8' && !this.isOnBoarding;
    return (
      this.currentStep != '1' &&
      this.currentStep != '8' &&
      !this.isOnBoarding &&
      !this.ongoingOpp &&
      !this.existingClient &&
      !this.cs
    );
  }

  get isEnableFinish() {
    if (this.cs && this.crossSellingMsg) {
      return false;
    }

    return this.currentStep === this.stepsCount.toString() /*&& this.hasAcceptedConditions*/ || this.isOnBoarding; //TODO to be completed for onboarding process (validate should be greyed when on main page and not all required datas are fulfilled)
  }

  get isDisabledVaidateBtn() {
    // grey validate button if conditions are not checked
    return !this.hasAcceptedConditions;
  }

  get hasStore() {
    return this.companyInfos.storesList.length > 0;
  }

  get hasFinCenter() {
    return this.companyInfos.finCentersList.length > 0;
  }

  get hasMultipleFinCenter() {
    return this.companyInfos.finCentersList.length > 1;
  }

  get displayFiscalId() {
    return this.companyInfos.countryCode === 'LU';
  }

  get showMsg() {
    let result =
      (this.activatedAccount && !this.onboardingAccount && this.hasContract) ||
      this.expiredQuote ||
      this.ongoingOpp ||
      this.existingClient ||
      this.urlStateParameters.crn ||
      this.companyInfos.badUserEmail ||
      this.existingMerchantStore;
    debugLog(
      this.dbg,
      '>>> showMsg() - this.ongoingOpp / existingClient' + this.ongoingOpp + ' - ' + this.existingClient
    );
    debugLog(this.dbg, '>>> showMsg() - result ' + result);
    return result;
  }

  get infoMsg() {
    debugLog(this.dbg, '>>> infoMsg() - this.companyInfos ' + JSON.stringify(this.companyInfos));
    return this.activatedAccount && !this.onboardingAccount && this.hasContract
      ? this.labels.lb_err_msg_existing_company
      : this.expiredQuote
      ? this.labels.lb_err_msg_expired_quote
      : this.companyInfos.badUserEmail == 'true'
      ? buildTemplate(this.labels.lb_err_msg_bad_user, [this.companyInfos.mainContact])
      : this.ongoingOpp
      ? this.handleOnboarding(this.companyInfos.accountId) // this.labels.lb_err_msg_opp_in_prog // SLI => 3443
      : this.existingClient || this.existingMerchantStore
      ? this.labels.lb_err_msg_existing_company_oa
      : null;
    // this.onboardingAccount && this.contractNbChecked ? this.labels.onboardingEndMessage :
  }

  get showAddFinCenter() {
    return this.companyInfos.finCentersList.length && !this.isReadOnly;
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
    const storeIndex = this.companyInfos.storesList.findIndex((store) => store.storeId === this.storeInfos.storeId);
    this.companyInfos.storesList[storeIndex].storeIndex = storeIndex;
    return this.companyInfos.storesList[storeIndex];
  }

  get defaultInvoicingMethod() {
    return this.country == 'FI' && this.companyInfos['Invoicing method'] == null
      ? 'E-Invoice'
      : this.companyInfos['Invoicing method'];
  }

  get endMessage() {
    let endMsg =
      !this.cs && this.scope == 'M' ? this.labels.lb_end_msg_onboarding : this.labels.lb_step_end_msg_greetings4;
    return this.crossSellingErrMsg ? this.crossSellingErrMsg : endMsg;
  }

  switchLanguage(lang) {
    this.lang = lang;
    this.labels = {
      ...this.labelsAllLangs[this.lang],
      ...this.labelsAllLangs['All']
    };
    this.tableLabels.lb_edit = this.labels.lb_edit;
    this.tableLabels.lb_delete = this.labels.lb_delete;

    let tcUrl = this.labels.lb_oa_terms_conditions_url ? this.labels.lb_oa_terms_conditions_url : '';
    let priceListUrl = this.labels.lb_oa_price_list_url ? this.labels.lb_oa_price_list_url : '';
    this.acceptTermsPrice = buildTemplate(this.labels.lb_step3_msg_accept_conditions, [tcUrl, priceListUrl]);

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

    // this.merchantUsersListTableColumns = {
    //   userName: this.labels.lb_step2b_user,
    //   userEmail: this.labels.lb_step1_email,
    //   contractNb: this.labels.lb_contract_nb
    // };

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
      this.companyInfos.storesList.forEach((store) => {
        if (store.terminalInfos.terminalProvider) this.setTIDPlaceholder(store);
      });
    }
    if (this.currentStep == '5') this.initCategories();
    if (this.currentStep == '7') this.initTermsAndConditions();
    // if (this.isOnBoarding && this.companyInfos.company) this.initCompanyInfos();
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

        this.picklistGroup.country = formatPicklist(data.pk_country, this.companyInfos.country);
        this.picklistGroup.role = formatPicklist(data.pk_role, this.companyInfos.role);
        this.picklistGroup.lang = formatPicklist(data.pk_lang, this.companyInfos.lang);
        this.picklistGroup.salutation = formatPicklist(data.pk_salutation, this.companyInfos.salutation);

        // Picklist for refund contact
        this.picklistGroup.refundSalutation = formatPicklist(data.pk_salutation, this.finCenterInfos.refundSalutation);
        this.picklistGroup.refundLang = formatPicklist(data.pk_lang, this.finCenterInfos.refundLang);
        this.picklistGroup.refundRole = formatPicklist(data.pk_role, this.finCenterInfos.refundRole);
        this.picklistGroup.refundCountry = formatPicklist(data.pk_country, this.finCenterInfos.refundCountry);

        // Picklist for stores
        this.picklistGroup.storeCountry = formatPicklist(data.pk_country);
        this.picklistGroup.isFranchisee = formatPicklist(data.pk_yes_no);
        // this.picklistGroup.sector = this.solution.startsWith('TR')
        // this.picklistGroup.sector = this.solution.match(/ERBE_TR.*|ERLU_TR.*/)
        //   ? formatPicklist(data.pk_sector)
        //   : formatPicklist(data.pk_sector_tce_tre);
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

        this.picklistGroup.invoicingMethod = formatPicklist(data.pk_invoicing_method);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
      });
  }

  handleNext() {
    this.validateStep();
    if (this.stepValidated) {
      switch (this.currentStep) {
        case this.stepsCount.toString():
        case this.stepsCount.toString():
          if (this.cs) {
            // Case cross selling
            // activateSolutionCrossSelling({ accountId: this.companyInfos.accountId, headContactId: this.companyInfos.contactId, buCode: this.country, scope: this.scope, solution: this.solution })

            if (this.scope == 'C') this.selectedProduct = this.solution;

            let params =
              this.companyInfos.accountId +
              '|' +
              this.companyInfos.contactId +
              '|' +
              this.country +
              '|' +
              this.scope +
              '|' +
              this.selectedProduct +
              '|' +
              this.erfiCardType +
              '|' +
              (this.additionalSelectedProducts ? this.additionalSelectedProducts : '-');
            debugLog(this.dbg, '>>> activateSolutionCrossSelling() this.selectedProduct ' + this.selectedProduct);
            debugLog(this.dbg, '>>> activateSolutionCrossSelling() this.erfiCardType ' + this.erfiCardType);
            debugLog(
              this.dbg,
              '>>> activateSolutionCrossSelling() this.additionalSelectedProducts ' + this.additionalSelectedProducts
            );
            debugLog(this.dbg, '>>> activateSolutionCrossSelling() params ' + params);
            doApexEvent({ operationName: 'activateSolutionCrossSelling', operationParams: params })
              .then((data) => {
                debugLog(this.dbg, '>>> activateSolutionCrossSelling() data ' + JSON.stringify(data));
                this.showSpinner = false;
                this.currentStep = '8';
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> activateSolutionCrossSelling() error ' + error);
              });
          } else {
            this.currentStep = '8';
          }
          break;
        case '1':
          this.currentStep = '2';
          break;
        case '2':
          this.currentStep = '3';
          break;
        case '3':
          this.currentStep = '4';
          break;
      }
    }
    // this.validateStep();
    // debugLog(this.dbg, 'handleNext, stepValidated: ' + this.stepValidated);
    // if (this.stepValidated) {
    //   // TODO create separate methods for each step in order to lighten the code
    //   switch (this.currentStep) {
    //     case '1':
    //       debugLog(this.dbg, 'handleNext - upsertLead. this.companyInfos = ' + JSON.stringify(this.companyInfos));

    //       if (this.version) {
    //         this.initTermsAndConditions(); // Auto enrollment v2 - prepare terms & conditions
    //         // this.retrieveOnboardingMsg();
    //       }
    //       if (!this.isReadOnly && !this.isWebOffer && !this.activatedAccount && !this.existingAccount && !this.isConvertedLead) {
    //         // Do lead conversion: first, update lead then do conversion
    //         doApexEvent({
    //           operationName: 'upsertLead',
    //           operationParams: JSON.stringify(this.companyInfos)
    //         })
    //           .then((data) => {
    //             debugLog(this.dbg, '>>> convertLead() Update - data ' + JSON.stringify(data));
    //             debugLog(this.dbg, '>>> convertLead() Update - this.companyInfos.leadId ' + this.companyInfos.leadId);

    //             if (this.companyInfos.keyId == undefined) this.companyInfos.keyId == '';
    //             doApexEvent({
    //               operationName: 'convertLead',
    //               operationParams:
    //                 '{"leadId": "' +
    //                 this.companyInfos.leadId +
    //                 '", "countryCode": "' +
    //                 this.country +
    //                 '", "solution": "' +
    //                 this.solution +
    //                 '", "scope": "' +
    //                 this.scope +
    //                 '", "promoCode": "' +
    //                 this.companyInfos.promoCode +
    //                 '", "keyId": "' +
    //                 this.companyInfos.keyId +
    //                 '", "enterpriseNb": "' +
    //                 this.companyInfos.enterpriseNb +
    //                 '"}'
    //             })
    //               .then((data) => {
    //                 this.isConvertedLead = true;
    //                 debugLog(this.dbg, '>>> convertLead() Convert - data ' + JSON.stringify(data));
    //               })
    //               .catch((error) => {
    //                 debugLog(this.dbg, '>>> convertLead() - error ' + error);
    //               });

    //             this.currentStep = '2';
    //           })
    //           .catch((error) => {
    //             debugLog(this.dbg, '>>> convertLead() - error ' + error);
    //           });
    //       } else if (this.isWebOffer || (this.existingAccount && !this.hasContract) || this.isConvertedLead) {
    //         updateAccount({
    //           merchantInfosJSON: JSON.stringify(this.companyInfos)
    //         })
    //           .then((data) => {
    //             this.currentStep = '2';
    //           })
    //           .catch((error) => {
    //             debugLog(this.dbg, '>>> updateAccount() - error ' + error);
    //           });
    //         // this.isReadOnlyEditable = true;
    //       }

    //       if (this.isReadOnly || this.isWebOffer || this.isOnBoarding) {
    //         // Get stores infos
    //         debugLog(this.dbg, '>>> getStoresInfos() - Start with accountId ' + this.companyInfos.accountId);
    //         getStoresInfos({
    //           accountId: this.companyInfos.accountId,
    //           locale: this.locale
    //         })
    //           .then((data) => {
    //             debugLog(this.dbg, '>>> getStoresInfos() - data ' + JSON.stringify(data));
    //             data.forEach((elem) => {
    //               let store = {};
    //               store.noDelete = true; // to hide delete button in data table
    //               Object.keys(elem).forEach((key) => {
    //                 store[key] = elem[key];
    //               });
    //               debugLog(this.dbg, '>>> getStoresInfos() - store.hasTerminal ' + store.hasTerminal);

    //               store.terminalInfos = store.hasTerminal ? store.terminalsList[0] : {};
    //               if (!store.hasTerminal) store.isNew = true;
    //               store.showContent = false;

    //               this.setRowIndex(store.terminalInfos, store.terminalsList, 'terminalId');

    //               debugLog(
    //                 this.dbg,
    //                 '>>> getStoresInfos() - store.chosenCategories ' + JSON.stringify(store.chosenCategories)
    //               );
    //               this.companyInfos.storesList.push(JSON.parse(JSON.stringify(store)));
    //             });

    //             if (this.companyInfos.storesList.length > 0) {
    //               this.storeInfos = JSON.parse(JSON.stringify(this.companyInfos.storesList[0]));
    //               this.picklistGroup.sector = initPicklistValue(this.picklistGroup.sector, this.storeInfos.sector);
    //               this.picklistGroup.isFranchisee = initPicklistValue(
    //                 this.picklistGroup.isFranchisee,
    //                 this.storeInfos.isFranchisee
    //               );
    //               this.picklistGroup.storeCountry = initPicklistValue(
    //                 this.picklistGroup.storeCountry,
    //                 this.storeInfos.country
    //               );
    //               this.picklistGroup.storeContactSalutation = initPicklistValue(
    //                 this.picklistGroup.storeContactSalutation,
    //                 this.storeInfos.storeContactSalutation
    //               );
    //               this.picklistGroup.storeContactLang = initPicklistValue(
    //                 this.picklistGroup.storeContactLang,
    //                 this.storeInfos.storeContactLanguage
    //               );
    //               if (this.hasMultipleFinCenter) {
    //                 this.setFinCenterpicklist();
    //                 this.picklistGroup.finCenterId = initPicklistValue(
    //                   this.picklistGroup.finCenterId,
    //                   this.storeInfos.finCenterId
    //                 );
    //                 debugLog(
    //                   this.dbg,
    //                   '>>> getStoresInfos() - this.storeInfos.finCenterId ' +
    //                     JSON.stringify(this.storeInfos.finCenterId)
    //                 );
    //                 debugLog(
    //                   this.dbg,
    //                   '>>> getStoresInfos() - this.picklistGroup.finCenterId ' +
    //                     JSON.stringify(this.picklistGroup.finCenterId)
    //                 );
    //               }
    //               this.setRowIndex(this.storeInfos, this.companyInfos.storesList, 'storeId');
    //             } else if (this.companyInfos.finCentersList.length == 1) {
    //               //V2 onboarding: init default contact for store, check if to be kept?
    //               debugLog(this.dbg, '>>> getStoresInfos() - one FC, init store contact ');
    //               this.storeInfos.storeContactSalutation = this.companyInfos.finCentersList[0].refundSalutation;
    //               this.storeInfos.storeContactFirstName = this.companyInfos.finCentersList[0].refundFirstName;
    //               this.storeInfos.storeContactLastName = this.companyInfos.finCentersList[0].refundLastName;
    //               this.storeInfos.storeContactEmail = this.companyInfos.finCentersList[0].refundEmail;
    //               this.storeInfos.storeContactLanguage = this.companyInfos.finCentersList[0].refundLang;
    //               debugLog(
    //                 this.dbg,
    //                 '>>> getStoresInfos() - this.storeInfos contact ' +
    //                   this.storeInfos.storeContactFirstName +
    //                   ' ' +
    //                   this.storeInfos.storeContactLastName
    //               );
    //             }

    //             // Init common chosenCategories with 1st store datas
    //             if (this.companyInfos.storesList[0])
    //               this.chosenCategories = JSON.parse(JSON.stringify(this.companyInfos.storesList[0].chosenCategories));

    //             debugLog(this.dbg, '>>> getStoresInfos() - this.storeInfos ' + JSON.stringify(this.storeInfos));
    //             debugLog(this.dbg, '>>> getStoresInfos() - this.companyInfos ' + JSON.stringify(this.companyInfos));
    //             debugLog(
    //               this.dbg,
    //               '>>> getStoresInfos() - this.chosenCategories ' + JSON.stringify(this.chosenCategories)
    //             );
    //           })
    //           .catch((error) => {
    //             debugLog(this.dbg, '>>> getStoresInfos() - error ' + error);
    //           });
    //         this.currentStep = '2';
    //       }
    //       break;

    //     case '2':
    //       debugLog(this.dbg, '>>> createFinCenters() - before ' + JSON.stringify(this.companyInfos.finCentersList));
    //       if (!this.isReadOnly) {
    //         doApexEvent({
    //           operationName: 'createFinCenters',
    //           operationParams: this.companyInfos.leadId + '|' + JSON.stringify(this.companyInfos.finCentersList)
    //         })
    //           .then((data) => {
    //             debugLog(this.dbg, '>>> createFinCenters() - data ' + JSON.stringify(data));
    //           })
    //           .catch((error) => {
    //             debugLog(this.dbg, '>>> createFinCenters() - error ' + error);
    //           });

    //         if (!this.isWebOffer) {
    //           // Skip opportunity update for web offers
    //           this.companyInfos.promoCode = this.companyInfos.promoCode ? this.companyInfos.promoCode : '';
    //           this.updateOpportunity();
    //         }
    //       }

    //       debugLog(this.dbg, 'handleNext, this.version: ' + this.version);

    //       if (!this.version) {
    //         // Auto enrollment v1 if version not defined
    //         // Prepare Acceptor picklist datas ahead for the next step
    //         this.retrieveAcceptorModels();

    //         if (this.isWebOffer) this.isReadOnlyEditable = true;

    //         this.currentStep = '3';
    //       } else {
    //         // Auto enrollment v2
    //         // Prepare onboarding URL for the final step
    //         this.currentStep = '7';
    //       }
    //       break;

    //     // case "3":
    //     //   debugLog(this.dbg, ">>> createStores() *** START *** storesList: " + JSON.stringify(this.companyInfos.storesList));
    //     //   if(!this.isReadOnly){
    //     //       this.companyInfos.storesList.forEach((store) => {  store.chosenCategories = JSON.parse(JSON.stringify(this.chosenCategories));
    //     //                                                           store.categorieItemsIds = this.categorieItems.map(cat => cat.id);} ); // categorieItemsIds is used to delete previous categories selected for current solution
    //     //     debugLog(this.dbg, ">>> createStores() - before create: " + JSON.stringify(this.companyInfos.storesList));
    //     //     doApexEvent({ operationName: 'createStores', operationParams: this.companyInfos.leadId + '|' + JSON.stringify(this.companyInfos.storesList) })
    //     //     .then((data) => {
    //     //       debugLog(this.dbg, ">>> createStores() - data " + JSON.stringify(data));
    //     //     })
    //     //     .catch((error) => { debugLog(this.dbg, ">>> createStores() - error " + error); });
    //     //   }

    //     //   if(this.isOnBoarding){
    //     //     this.currentStep = null;
    //     //   } else {
    //     //     // Retrieve categories in terminals step in order prepare datas ahead
    //     //     this.initCategories();
    //     //     this.currentStep = "4";
    //     //   }

    //     //   break;

    //     case '4':
    //       if (!this.isOnBoarding) {
    //         debugLog(this.dbg, '>>> createTerminals() - before ' + JSON.stringify(this.companyInfos.storesList));
    //         doApexEvent({
    //           operationName: 'createTerminals',
    //           operationParams: this.companyInfos.leadId + '|' + JSON.stringify(this.companyInfos.storesList)
    //         })
    //           .then((data) => {
    //             debugLog(this.dbg, '>>> createTerminals() - data ' + JSON.stringify(data));
    //           })
    //           .catch((error) => {
    //             debugLog(this.dbg, '>>> createTerminals() - error ' + error);
    //           });

    //         this.currentStep = !this.isReadOnly ? '5' : '6';
    //       } else {
    //         this.currentStep = '3';
    //       }

    //       break;

    //     case '5':
    //       // Prepare arrays for chosen categories
    //       // this.companyInfos.storesList.forEach((store) => {
    //       // this.chosenCategories.push(...this.categorieItems.filter((elem) => elem.isChecked));
    //       // debugLog(this.dbg, ">>> Chosen cats - nb chosenCategories" + this.chosenCategories.length);
    //       // });

    //       // Get Terms and conditions previously
    //       if (!this.isOnBoarding) this.initTermsAndConditions();

    //       this.currentStep = '6';
    //       break;

    //     case '6':
    //       // debugLog(this.dbg, ">>> Step7 - createCategories() - this.companyInfos.storesList " + JSON.stringify(this.companyInfos.storesList));
    //       // debugLog(this.dbg, ">>> Step7 - createCategories() - this.isReadOnly " + this.isReadOnly );
    //       // if(!this.isReadOnly){
    //       //   let merchantId = (this.companyInfos.leadId) ? this.companyInfos.leadId : this.companyInfos.accountId;  // In case of Weboffer, pass account Id (as may be no lead Id available)
    //       //   debugLog(this.dbg, ">>> Step7 - createCategories() - merchantId " + merchantId);
    //       //   doApexEvent({ operationName: 'createCategories', operationParams: merchantId + '|' + JSON.stringify(this.companyInfos.storesList) })
    //       //   .then((data) => { debugLog(this.dbg, ">>> createCategories() - data " + JSON.stringify(data)); })
    //       //   .catch((error) => { debugLog(this.dbg, ">>> createCategories() - error " + error); });
    //       // }

    //       if (!this.isOnBoarding) {
    //         this.currentStep = !this.isReadOnly ? '7' : '8';
    //       } else {
    //         this.currentStep = '3';
    //       }

    //       break;

    //     case '7':
    //       let paramsJSON = {
    //         leadId: this.companyInfos.leadId,
    //         country: this.companyInfos.countryCode,
    //         contactEmail: this.companyInfos.email,
    //         lang: this.lang,
    //         solution: this.solution,
    //         promoCode: this.companyInfos.promoCode,
    //         scope: this.scope,
    //         versionId: this.termsAndConditions.tcVersion,
    //         uniqueKeyId: this.uniqueKeyId,
    //         isWebOffer: this.isWebOffer,
    //         version: this.version
    //       }; // param for Web offers

    //       debugLog(this.dbg, '>>> Step7 - closeOpportunity() - paramsJSON ' + JSON.stringify(paramsJSON));

    //       doApexEvent({
    //         operationName: 'closeOpportunity',
    //         operationParams: JSON.stringify(paramsJSON)
    //       })
    //         .then((data) => {
    //           debugLog(this.dbg, '>>> closeOpportunity() - data ' + JSON.stringify(data));
    //         })
    //         .catch((error) => {
    //           debugLog(this.dbg, '>>> closeOpportunity() - error ' + error);
    //         });
    //       this.currentStep = '8';
    //       break;
    //   }
    //   this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
    //   this.stepValidated = false;

    //   saveToFile({ merchantInfosJSON: JSON.stringify(this.companyInfos) })
    //     .then(() => {
    //       debugLog(this.dbg, '>>> saveToFile() - done ');
    //     })
    //     .catch((error) => {
    //       debugLog(this.dbg, '>>> saveToFile() - error ' + error);
    //     });
    // }
  }

  handleInternalOnboarding() {
    getAccountIdFromCRN({ crn: this.companyInfos.enterpriseNb })
      .then((accountId) => {
        let url = document.location.href;
        let urlParts = url.split('/');
        let obt = '';
        let redirectionUrl =
          'https://' +
          urlParts[2] +
          '/s/auto-enrollment-onboarding-' +
          this.country.toLowerCase() +
          '?crn=' +
          this.companyInfos.enterpriseNb +
          '&language=' +
          this.lang +
          '&scope=M' +
          '&obt=' +
          accountId +
          '&product=' +
          this.solution;

        window.location.href = encodeURI(redirectionUrl);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getAccountIdFromCRN() - error ' + error);
      });
  }

  handleOnboarding() {
    // SLI => 3443
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/auto-enrollment-onboarding-' +
      this.country.toLowerCase() +
      '?crn=' +
      this.companyInfos.enterpriseNb +
      '&language=' +
      this.lang +
      '&scope=M&product=' +
      this.solution;

    window.location.href = encodeURI(redirectionUrl);
  }

  handlePrev() {
    let curStep = this.currentStep;
    debugLog(this.dbg, 'handlePrev - curStep = ' + curStep);

    if (curStep == '7') curStep = '2';
    else if (curStep == '6') curStep = !this.isReadOnly ? '5' : '4';
    else if (curStep == '5') curStep = '4';
    else if (curStep == '4') curStep = '3';
    else if (curStep == '3') {
      curStep = '2';
      this.hasAcceptedConditions = false;
    } else if (curStep == '2') curStep = '1';
    this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
    this.currentStep = curStep;
    debugLog(this.dbg, 'handlePrev - END - this.currentStep = ' + this.currentStep);
  }

  handleCheckEnterpriseNb() {
    debugLog(this.dbg, '>>> handleCheckEnterpriseNb : ' + this.companyInfos.enterpriseNb);
    this.companyInfos.enterpriseNb = this.companyInfos.enterpriseNb.replace(/\s|\./g, ''); //remove dots before processing
    let enterpriseNb = this.companyInfos.enterpriseNb;

    if (this.dbg && this.isSandbox) this.isRecaptchaSuccess = true;
    debugLog(this.dbg, '>>> handleCheckEnterpriseNb() - this.isRecaptchaSuccess ' + this.isRecaptchaSuccess);

    let inputFields = [...this.template.querySelectorAll('c-er-portal-input')]; // this kind of assignment is done in order to be able to use .filter() function later
    let checkFields =
      checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && this.validateFieldsFormat(inputFields);

    if (!this.isRecaptchaSuccess && !this.urlStateParameters.crn) {
      //Check captcha success, except if cross selling (ie crn in url)
      this.showToast(this.labels.lb_error, this.labels.lb_err_msg_captcha, 'error');
    } else if (!enterpriseNb || (!isValidEnterpriseNb(enterpriseNb, this.country) && checkFields)) {
      let paramsValues = [];
      paramsValues.push(this.labels.lb_enterprise_nb_format);
      let errMsg = buildTemplate(this.labels.lb_step1_errmsg_enterprise_nb, paramsValues);
      this.showToast(this.labels.lb_error, errMsg, 'error');
    } else {
      this.showSpinner = true;
      debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- this.showSpinner: ' + this.showSpinner);
      debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- this.solution ' + this.solution);

      getCompanyInfosCore({
        enterpriseNb: enterpriseNb,
        country: this.country,
        lang: this.lang,
        solutionCode: this.solution,
        scopeFlow: this.scope,
        crossSelling: this.cs,
        isOnBoarding: false
      })
        .then((data) => {
          // this.isReadOnly = JSON.parse(data.isReadOnly.toLowerCase());
          this.existingAccount = data.existingAccount ? JSON.parse(data.existingAccount.toLowerCase()) : false;
          this.ongoingOpp = data.ongoingOpp ? JSON.parse(data.ongoingOpp.toLowerCase()) : false;
          this.shouldOnboard = data.shouldOnboard ? JSON.parse(data.shouldOnboard.toLowerCase()) : false;
          this.existingClient = data.existingClient ? JSON.parse(data.existingClient.toLowerCase()) : false;
          this.existingMerchantStore = data.existingMerchantStore
            ? JSON.parse(data.existingMerchantStore.toLowerCase())
            : false;
          let inactive = data.inactive ? JSON.parse(data.inactive.toLowerCase()) : false;
          if (inactive) {
            this.showToast(this.labels.lb_error, this.labels.lb_err_msg_inactive_crn, 'error');
            this.hasCheckedEnterpriseNb = false;
          }
          this.invalidScope = data.invalidScope ? JSON.parse(data.invalidScope.toLowerCase()) : false;
          this.invalidProduct = data.solutionNotListedInProducts
            ? JSON.parse(data.solutionNotListedInProducts.toLowerCase())
            : false;
          this.activeProduct = data.activeProduct ? JSON.parse(data.activeProduct.toLowerCase()) : false;

          debugLog(
            this.dbg,
            '>>> handleCheckEnterpriseNb -- this.ongoingOpp / existingClient' +
              this.ongoingOpp +
              ' - ' +
              this.existingClient
          );
          debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- showMsg()  ' + this.showMsg);
          debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- data ' + JSON.stringify(data));

          if (
            !this.ongoingOpp &&
            (this.cs || !this.existingClient) &&
            !inactive &&
            (this.cs || !this.existingMerchantStore)
          ) {
            this.companyInfos = {};
            this.companyInfos.enterpriseNb = enterpriseNb;
            this.companyInfos.storesList = [];
            this.companyInfos.finCentersList = [];
            this.companyInfos.usersList = [];
            this.companyInfos.promoCode = '';

            Object.keys(data).forEach((key) => {
              this.companyInfos[key] = key != 'contractsJSON' ? data[key] : JSON.parse(data[key]);
            });

            if (this.cs && this.companyInfos.companyName) {
              // use company Name not Legal_Name__c
              this.companyInfos.legalName = this.companyInfos.companyName;
            }

            if (this.shouldOnboard) {
              this.handleOnboarding(this.companyInfos.accountId);
            }

            if (this.companyInfos.isVirtualCard) this.companyInfos.serviceName = this.labels.lb_virtual_card;

            this.onboardingAccount = this.companyInfos.Draft; // Show message to redirect onboarding
            if (this.onboardingAccount) {
              //   this.retrieveOnboardingDatas();
            } else if (!this.ongoingOpp && !this.existingClient && !inactive && !this.shouldOnboard) {
              debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- getEnterpriseInfos() - data ' + JSON.stringify(data));
              this.hasCheckedEnterpriseNb = true;
              //TODO to be moved if CRN OK
              // this.companyInfos.hasVATCode = true;
              // this.setVATCode();

              // Init picklist with right value
              this.picklistGroup.country = initPicklistValue(this.picklistGroup.country, this.companyInfos.country); // TODO move this part to Utils as initSelectPicklist() function
            }
            debugLog(
              this.dbg,
              '>>> handleCheckEnterpriseNb -- this.isReadOnly - activatedAccount - onboardingAccount - existingLead: ' +
                this.isReadOnly +
                '-' +
                this.activatedAccount +
                '-' +
                this.onboardingAccount +
                '-' +
                this.existingLead
            );
            if (
              !this.isReadOnly &&
              !this.activatedAccount &&
              !this.ongoingOpp &&
              !this.existingClient &&
              !this.onboardingAccount &&
              !this.companyInfos.existingLead
            ) {
              // Create lead if new merchant
              debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- upsertLead (not done for now)');
              this.companyInfos.countryCode = !this.companyInfos.countryCode
                ? this.country
                : this.companyInfos.countryCode;
              this.companyInfos.solution = this.solution;
              this.companyInfos.scope = this.scope;
              this.companyInfos.lang = this.lang;

              if (!this.cs) {
                //AAM 12.06.23 no need to create lead in cross selling context (no structure modification, only solution activation)
                upsertLeadCore({ companyInfosJSON: JSON.stringify(this.companyInfos) })
                  .then((data) => {
                    debugLog(this.dbg, '>>> upsertLeadCore() - data ' + JSON.stringify(data));
                    this.companyInfos.leadId = data.leadId;
                    debugLog(this.dbg, '>>> upsertLeadCore() - this.companyInfos.leadId ' + this.companyInfos.leadId);
                  })
                  .catch((error) => {
                    debugLog(this.dbg, '>>> upsertLeadCore() - error ' + JSON.stringify(error));
                  });
              }

              if (this.companyInfos.countryCode == 'FI') {
                getProductListNames({ buCode: this.companyInfos.countryCode })
                  .then((data) => {
                    debugLog(this.dbg, '>>> getProductListNames() - data ' + JSON.stringify(data));
                    this.additionalProducts = data;
                    // this.erfiCardType = this.labels.lb_virtual_card;
                    this.erfiBenefits = this.labels.lb_opt_lunch_virike;

                    if (!this.companyInfos.numberEmployees) this.companyInfos.numberEmployees = 1; // set min value if undefined (otherwise products not displayed)
                    this.setProductList();                  })
                  .catch((error) => {
                    debugLog(this.dbg, '>>> getProductListNames() - error ' + error);
                    debugLog(this.dbg, '>>> getProductListNames() - error ' + JSON.stringify(error));
                  });
              }

              // Set main productif not already done previously
              if (!this.productList.length && !this.cs)
                this.productList.push({
                  labels: { cardName: this.companyInfos.mainSolutionName },
                  isMandatory: true,
                  optionsList: [{ optionText: this.companyInfos.serviceName }]
                });
            } else if (this.cs && this.getCrossSellingMsg() == undefined) {
              this.setProductList();
            }
          }
          this.showSpinner = false;
          debugLog(this.dbg, '>>> handleCheckEnterpriseNb -- this.showSpinner2: ' + this.showSpinner);

          if (this.cs) {
            // cross selling link
            this.currentStep = this.stepsCount.toString();
          }

          // Unsubscribe from message channel used by recaptcha
          unsubscribe(this.subscription);
          this.subscription = null;
          this.showHeader = this.shouldOnboard ? false : true;
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getCompanyInfosCore() - error ' + JSON.stringify(error));
          debugLog(this.dbg, '>>> getCompanyInfosCore() - error2 ' + error);
          if (this.cs) {
            // cross selling link
            this.currentStep = this.stepsCount.toString();
          } else {
            this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_crn, 'error');
          }
          this.hasCheckedEnterpriseNb = false;
          this.showSpinner = false;
        });
    }
  }

  // async handleCheckContractNb() {
  //   debugLog(this.dbg, '>>> handleCheckContractNb *** START **** contractNb: ' + this.companyInfos.contractNb);
  //   if (
  //     await checkContractNb({
  //       enterpriseNb: this.companyInfos.enterpriseNb,
  //       contractNb: this.companyInfos.contractNb
  //     })
  //   ) {
  //     this.contractNbChecked = true;
  //     this.currentStep = null;
  //     // this.initCategories();
  //     debugLog(this.dbg, '>>> handleCheckContractNb() - result OK ');
  //   } else {
  //     this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_contract_nb, 'error');
  //     debugLog(this.dbg, '>>> handleCheckContractNb() - result wrong contract ');
  //   }
  // }

  //   retrieveOnboardingDatas() {
  //     debugLog(
  //       this.dbg,
  //       '>>> retrieveOnboardingDatas() - this.companyInfos accountId - contractId: ' +
  //         this.companyInfos.accountId +
  //         ' - ' +
  //         this.companyInfos.contractId
  //     );
  //     getOnBoardingDatas({
  //       accountId: this.companyInfos.accountId,
  //       contractId: this.companyInfos.contractId
  //     }).then((data) => {
  //       debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.companyInfos2 data: ' + JSON.stringify(data));
  //       Object.assign(this.companyInfos, data); // merge objects
  //       this.initCompanyInfos();
  //       // this.companyInfos.accountId = data.accountId;
  //       debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.companyInfos2 ' + JSON.stringify(this.companyInfos));

  //       // Populate data tables with empty records if no data yet (for the display)
  //       if (!this.hasStore) {
  //         this.companyInfos.storesList.push({
  //           name: '',
  //           fullAddress: '',
  //           finCenterName: '',
  //           finCenterId: 1
  //         });
  //       } else {
  //         this.companyInfos.storesList.forEach((store) => {
  //           if (store.terminalsList && store.terminalsList.length > 0) store.hasTerminal = true;
  //           store.isWebShop = store.isWebShop == 'true';
  //           store.physicalTerminalAccepted = store.physicalTerminalAccepted == 'true';
  //           store.mastercardAccepted = store.mastercardAccepted == 'true';
  //           store.virtualTerminal = store.virtualTerminal == 'true';
  //           debugLog(this.dbg, '>>> getOnBoardingDatas() - store ' + JSON.stringify(store));
  //         });
  //         debugLog(
  //           this.dbg,
  //           '>>> retrieveOnboardingDatas() - this.companyInfos.storesList[0].chosenCategories ' +
  //             JSON.stringify(this.companyInfos.storesList[0].chosenCategories)
  //         );
  //       }
  //       if (!this.hasMerchantUser) {
  //         this.companyInfos.usersList = [];
  //         this.companyInfos.usersList.push({
  //           userName: '',
  //           userEmail: '',
  //           contractNb: '',
  //           userId: 1
  //         });
  //         this.merchantUserInfos.userId = 1;
  //       }
  //       this.setFinCenterpicklist();
  //       debugLog(
  //         this.dbg,
  //         '>>> retrieveOnboardingDatas() - this.chosenCategories ' + JSON.stringify(this.chosenCategories)
  //       );
  //     });
  //     // .catch((error) => { debugLog(this.dbg, ">>> retrieveOnboardingDatas() - error " + JSON.stringify(error)); });
  //   }

  // initCategories() {
  //   debugLog(
  //     this.dbg,
  //     '>>> () initCategories ***START*** - params ' + this.companyInfos.countryCode + ' - ' + this.solution
  //   );
  //   this.categorieItems = [];
  //   if (this.chosenCategories.length > 0) this.chosenCategories.forEach((cat) => (previousCatsCsv += cat.id + ','));

  //   getCategories({
  //     country: this.companyInfos.countryCode,
  //     solution: this.solution,
  //     existingCatsCsv: previousCatsCsv
  //   })
  //     .then((data) => {
  //       const lang = this.lang.toLowerCase();
  //       const locale = Object.keys(data).filter((elem) => elem.toLowerCase().includes(lang))[0];
  //       debugLog(this.dbg, '>>> initCategories() - data: ' + JSON.stringify(data));
  //       debugLog(this.dbg, '>>> initCategories() - lang: ' + this.lang + ' , locale: ' + locale);
  //       this.categories = JSON.parse(JSON.stringify(data[locale])); // Dirty hack to prevent from "object is not extensible" exception

  //       // Do the sort
  //       let sortedtreeKeys = Object.keys(this.categories).sort();

  //       sortedtreeKeys.forEach((elem) => {
  //         this.categories[elem].treeKey = elem; // In order to manage display hide cat in handleToggleCategorie()
  //         this.categories[elem].showItem = this.categories[elem].level === '1'; //  Show only level 1 Items in the beginning
  //         this.categories[elem].className =
  //           this.categories[elem].level === '1' || this.categories[elem].isParent == 'true'
  //             ? 'categorie-item__parent'
  //             : 'categorie-item__child';
  //         this.categories[elem].selectable = this.categories[elem].isParent == 'true' ? false : true;
  //         this.categories[elem].levelOffset = 'margin-left:' + (this.categories[elem].level - 1) * 10 + '%;'; // Set the margin according to cat level
  //         if (!this.categories[elem].selectable) this.categories[elem].showChilds = false;

  //         this.categorieItems.push(this.categories[elem]);
  //       });

  //       if (this.companyInfos.storesList[0].chosenCategories.length > 0) {
  //         // let initChosenCategories = [];
  //         this.companyInfos.storesList[0].chosenCategories.forEach((cat) => {
  //           debugLog(this.dbg, '>>> initCategories() - cat: ' + JSON.stringify(cat));

  //           let catFound = false;
  //           this.categorieItems.forEach((cat2) => {
  //             if (cat2.id == cat.id && !catFound) {
  //               cat2.isChecked = cat.isChecked;
  //               cat2.isMain = cat.isMain;
  //               catFound = true;
  //             }
  //           });

  //           if (!catFound) {
  //             // case category from another solution
  //             this.chosenCategories.push(cat);
  //           }
  //         });
  //       }
  //       debugLog(this.dbg, '>>> initCategories() - ***END1*** ' + JSON.stringify(this.chosenCategories));
  //     })
  //     .catch((error) => {
  //       debugLog(this.dbg, '>>> initCategories() - error ' + error);
  //       debugLog(this.dbg, '>>> initCategories() - error str ' + JSON.stringify(error));
  //     });
  //   debugLog(this.dbg, '>>> initCategories() - ***END2*** ');
  // }

  //   initCompanyInfos() {
  //     debugLog(this.dbg, '>>> initCompanyInfos() - ***START***');
  //     this.companyInfos = [];
  //     this.companyInfos.push({
  //       [this.labels.lb_step1_enterprise_name]: this.companyInfos.company
  //     });
  //     this.companyInfos.push({
  //       [this.labels.lb_contract_nb]: this.companyInfos.contractNumber
  //     });
  //     this.companyInfos.push({
  //       [this.labels.lb_solution_name]: this.companyInfos.solutionName
  //     });
  //     debugLog(this.dbg, '>>> initCompanyInfos() - ***END000*** this.companyInfos: ' + JSON.stringify(this.companyInfos));
  //   }

  // generic handler as binding in lwc is one way and to avoid creating one handler per property
  handleCompanyInfos(event) {
    debugLog(this.dbg, 'handleCompanyInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value);
    this.companyInfos[event.detail.field] = event.detail.value;
    debugLog(this.dbg, 'handleCompanyInfos - new value for the field: ' + this.companyInfos[event.detail.field]);

    // set picklist to the right option
    if (event.detail.picklist) {
      debugLog(this.dbg, 'handleCompanyInfos is picklist ');
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
      debugLog(this.dbg, 'handleCompanyInfos new picklist: ' + JSON.stringify(this.picklistGroup[event.detail.field]));
    }

    if (event.detail.field === 'numberEmployees') {
      this.setProductList();
    }
    // // Check city according to postalCode
    // if (
    //   (event.detail.field === 'postalCode' || event.detail.field === 'city') &&
    //   this.companyInfos.postalCode &&
    //   this.companyInfos.city
    // ) {
    //   this.checkCity(this.companyInfos.city, this.companyInfos.postalCode, this.companyInfos, 'city');
    // }

    debugLog(this.dbg, 'handleCompanyInfos ***END*** ');
  }

  handleRegNbLength(event) {
    this.companyInfos[event.detail.field] = event.detail.value;
    this.disableCheckCompanyBtn = !(this.companyInfos.enterpriseNb && this.companyInfos.enterpriseNb?.length > 3);
    debugLog(this.dbg, '>>> handleRegNbLength() - this.disableCheckCompanyBtn ' + this.disableCheckCompanyBtn);
  }

  handleOptionChange(event) {
    debugLog(this.dbg, 'handleOptionChange2 - event.detail.optionName: ' + JSON.stringify(event.detail.optionName));
    debugLog(this.dbg, 'handleOptionChange2 - event.detail.value: ' + JSON.stringify(event.detail.value));

    switch (event.detail.optionName) {
      case 'CardType':
        this.erfiCardType = event.detail.value;
        this.setProductList();
        break;
      case 'Benefits':
        this.erfiBenefits = event.detail.value;
        this.setProductList();
        break;
      default:
        break;
    }
  }

  handleProductOnClick(event) {
    debugLog(this.dbg, 'handleProductOnClick - event.detail.value: ' + JSON.stringify(event.detail));
    this.selectedProduct = event.detail.value;
    if (event.detail.isSelected == true) {
      this.addtToAdditionalSelectedProducts(this.selectedProduct);
    } else {
      this.removeFromAdditionalSelectedProducts(this.selectedProduct);
    }
    debugLog(this.dbg, 'handleProductOnClick - this.additionnalSelectedProd: ' + this.additionalSelectedProducts);
    this.setProductList();
  }

  addtToAdditionalSelectedProducts(productCode) {
    const index = this.additionalSelectedProducts.indexOf(productCode);
    if (index == -1) this.additionalSelectedProducts.push(productCode);
  }

  removeFromAdditionalSelectedProducts(productCode) {
    const index = this.additionalSelectedProducts.indexOf(productCode);
    if (index > -1) this.additionalSelectedProducts.splice(index, 1);
  }

  setProductList() {
    // Temporary function, in order to move smoothly all business rules to erPortalBusinessRules lwc
    // the new function is only used in Client cross selling for now, all the other contexts will be moved later after intensive tests
    if (this.cs && this.scope == 'C') {
      this.productList = setProductListNew( this.companyInfos, this.labels, this.scope, this.solution, this.cs, this.erfiCardType, this.erfiBenefits, this.additionalProducts, this.selectedProduct );

      this.productList.forEach((prod) => {
        if(prod.isMandatory) this.addtToAdditionalSelectedProducts(prod.labels.productCode);
      });
    }
    else this.setProductListTobeReplaced();
  }

  setProductListTobeReplaced() {
    debugLog(this.dbg, 'setProductList - Start');
    this.productList = [];
    // Set main product
    let mainProduct = {
      labels: { cardName: this.companyInfos.mainSolutionName },
      isMandatory: true,
      optionsList: [{ optionText: this.companyInfos.serviceName }]
    };
    let otherProds = [];
    let cardOptionList = [
      {
        optionName: 'CardType',
        optionText: this.labels.lb_opt_card_type_question,
        choice1: this.labels.lb_virtual_card,
        choice2: this.labels.lb_physical_card
      },
      { optionText: this.labels.lb_opt_lunch_virike }
    ];
    let virtualCardOption = [{ optionText: this.labels.lb_virtual_card }];
    let btnLabels = {
      add: this.labels.lb_add,
      select: this.labels.lb_select,
      selected: this.labels.lb_selected,
      active: this.labels.lb_active
    };

    debugLog(this.dbg, 'setProductList - Start');

    if (!this.cs || this.scope == 'C') {
      switch (this.solution) {
        case 'ERFI_C_TD_DUALW_EUR':
          let cardTypeOption = {
            optionName: 'CardType',
            optionText: this.labels.lb_opt_card_type_question,
            choice1: this.labels.lb_virtual_card,
            choice2: this.labels.lb_physical_card,
            value: this.erfiCardType
          };
          let benefitsOption = {
            optionName: 'Benefits',
            optionText: this.labels.lb_opt_benefits_question,
            choice1: this.labels.lb_opt_lunch_virike,
            choice2: this.labels.lb_opt_lunch,
            value: this.erfiBenefits
          };
          mainProduct.optionsList.push(cardTypeOption);

          // Show benefits choice in Edenred Card product
          if (
            this.erfiCardType == this.labels.lb_physical_card ||
            (this.erfiCardType != this.labels.lb_physical_card &&
              Number(this.companyInfos.numberEmployees) >= Number(this.labels.default_erfi_td_nb_emp_min))
          ) {
            this.erfiBenefits == this.labels.lb_opt_lunch_virike;
            mainProduct.optionsList.push({ optionText: this.labels.lb_opt_lunch_virike });
          } else {
            mainProduct.optionsList.push(benefitsOption);
          }

          let prodCodeList;
          if (Number(this.companyInfos.numberEmployees) < Number(this.labels.default_erfi_td_nb_emp_min)) {
            if (this.erfiCardType == this.labels.lb_virtual_card) {
              prodCodeList =
                this.erfiBenefits == this.labels.lb_opt_lunch_virike
                  ? this.labels.default_erfi_td_prod_list1_csv
                  : this.labels.default_erfi_td_prod_list2_csv;
            } else {
              prodCodeList = this.labels.default_erfi_td_prod_list1_csv;
            }
          } else {
            prodCodeList = this.labels.default_erfi_td_prod_list1_csv;
          }

          prodCodeList.split(',').forEach((prodCode) => {
            otherProds.push({
              labels: { productCode: prodCode, cardName: this.additionalProducts[prodCode], ...btnLabels },
              optionsList: [{ optionText: this.labels.lb_virtual_card }]
            });
          });
          break;

        case 'ERFI_C_VOU_LUNCH':
          otherProds.push({
            labels: { productCode: 'ERFI_C_VOU_REC', cardName: this.additionalProducts['ERFI_C_VOU_REC'] },
            isMandatory: true
          });
          this.addtToAdditionalSelectedProducts('ERFI_C_VOU_REC');
          break;

        case 'ERFI_C_VOU_REC':
          if (Number(this.companyInfos.numberEmployees) >= Number(this.labels.default_erfi_td_nb_emp_min)) {
            otherProds = [
              {
                labels: { productCode: 'ERFI_C_VOU_LUNCH', cardName: this.additionalProducts['ERFI_C_VOU_LUNCH'] },
                isMandatory: true
              }
            ];
            this.addtToAdditionalSelectedProducts('ERFI_C_VOU_LUNCH');
          } else {
            otherProds = [
              {
                labels: { productCode: 'ERFI_C_VOU_LUNCH', cardName: this.additionalProducts['ERFI_C_VOU_LUNCH'] },
                isMandatory: true
              },
              {
                labels: {
                  productCode: 'ERFI_C_TD_DUALW_EUR',
                  cardName: this.additionalProducts['ERFI_C_TD_DUALW_EUR'],
                  ...btnLabels
                },
                optionsList: [{ optionText: this.labels.lb_virtual_card }, { optionText: this.labels.lb_opt_lunch }]
              }
            ];
            this.addtToAdditionalSelectedProducts('ERFI_C_VOU_LUNCH');
          }
          break;

        case 'ERFI_C_TTR_EUR':
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_TD_DUALW_EUR',
              cardName: this.additionalProducts['ERFI_C_TD_DUALW_EUR'],
              ...btnLabels
            },
            optionsList: cardOptionList
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_MASS_EUR',
              cardName: this.additionalProducts['ERFI_C_MASS_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_DENT_EUR',
              cardName: this.additionalProducts['ERFI_C_DENT_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          break;

        case 'ERFI_C_MASS_EUR':
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_TD_DUALW_EUR',
              cardName: this.additionalProducts['ERFI_C_TD_DUALW_EUR'],
              ...btnLabels
            },
            optionsList: cardOptionList
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_TTR_EUR',
              cardName: this.additionalProducts['ERFI_C_TTR_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_DENT_EUR',
              cardName: this.additionalProducts['ERFI_C_DENT_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          break;

        case 'ERFI_C_DENT_EUR':
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_TD_DUALW_EUR',
              cardName: this.additionalProducts['ERFI_C_TD_DUALW_EUR'],
              ...btnLabels
            },
            optionsList: cardOptionList
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_TTR_EUR',
              cardName: this.additionalProducts['ERFI_C_TTR_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          otherProds.push({
            labels: {
              productCode: 'ERFI_C_MASS_EUR',
              cardName: this.additionalProducts['ERFI_C_MASS_EUR'],
              ...btnLabels
            },
            optionsList: virtualCardOption
          });
          break;
      }
    } else {
      debugLog(this.dbg, 'setProductList - cross selling');

      if (this.scope == 'M') {
        let activeProds = [];
        let availableProds = [];
        debugLog(this.dbg, 'setProductList - cross selling Merchant');
        Object.keys(this.additionalProducts).forEach((prodCode) => {
          if (prodCode.startsWith('ERFI_M')) {
            let prod = {
              labels: { cardName: this.additionalProducts[prodCode], productCode: prodCode, ...btnLabels },
              isRadioBtn: true
            };
            prod.isSelected = this.selectedProduct == prodCode;

            this.solution;
            if (this.companyInfos.activeProductsCsv) {
              prod.isActivated = this.companyInfos.activeProductsCsv.includes(prodCode);
            }
            if (prod.isActivated) activeProds.push(prod);
            else {
              if (!this.companyInfos.ongoingOppProductsCsv) availableProds.push(prod);
              else if (!this.companyInfos.ongoingOppProductsCsv.includes(prodCode)) availableProds.push(prod);
            }
          }
        });

        otherProds.push(...activeProds, ...availableProds);
        debugLog(this.dbg, 'setProductList - cross selling otherProds: ' + JSON.stringify(otherProds));
      }
    }

    if (!this.cs || this.scope == 'C') this.productList.push(mainProduct);
    this.productList.push(...otherProds);
    debugLog(this.dbg, 'setProductList - this.productList end: ' + JSON.stringify(this.productList));
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
            // // to check if one of those fields "Contact phone" or "mobile" is populated
            // let checkMobileOrPhone;
            // let mobileOrPhoneFields = [];
            // mobileOrPhoneFields = inputFields.filter(
            //   (elem) => elem.propertyName === 'contactPhone' || elem.propertyName === 'mobile'
            // );

            // if (mobileOrPhoneFields[0].value || mobileOrPhoneFields[1].value) {
            //   debugLog(this.dbg, 'validateStep - mobileOrPhoneFields OK');
            //   checkMobileOrPhone = true;
            //   mobileOrPhoneFields[0].hasError = false;
            //   mobileOrPhoneFields[0].errorMessage = '';
            // } else {
            //   debugLog(this.dbg, 'validateStep - mobileOrPhoneFields error');
            //   checkMobileOrPhone = false;
            //   mobileOrPhoneFields[0].hasError = true;
            //   mobileOrPhoneFields[0].errorMessage = this.labels.lb_err_msg_required_field;
            // }

            // check email, gsm or tel, regex tel
            // checkFormats = this.validateFieldsFormat(inputFields);
            // this.stepValidated = checkFormats && checkMobileOrPhone && requiredFields;
            this.stepValidated = requiredFields;
            debugLog(this.dbg, 'validateStep (1) - this.stepValidated = ' + this.stepValidated);
            break;
          case '2':
            debugLog(this.dbg, 'validateStep - step2 ');
            requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field);
            checkFormats = this.validateFieldsFormat(inputFields);
            this.stepValidated = requiredFields && checkFormats;
            break;
          case '3':
            debugLog(this.dbg, 'validateStep - step3 ');
            if (this.scope == 'M') {
              requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field);
              checkFormats = this.validateFieldsFormat(inputFields);
              this.stepValidated = requiredFields && checkFormats;
            } else {
              this.convertLead();
            }
            break;
          case '4':
            this.convertLead();
            break;
        }

        if (
          this.stepValidated &&
          (['1', '2'].includes(this.currentStep) || (this.currentStep == '3' && this.scope != 'C'))
        ) {
          this.companyInfos.countryCode = !this.companyInfos.countryCode ? this.country : this.companyInfos.countryCode;
          this.companyInfos.solution = this.solution;
          this.companyInfos.scope = this.scope;
          this.companyInfos.lang = this.lang;
          debugLog(
            this.dbg,
            '>>> update Lead() doApexEvent upsertLeadCore params: ' + JSON.stringify(this.companyInfos)
          );
          // update lead
          doApexEvent({ operationName: 'upsertLeadCore', operationParams: JSON.stringify(this.companyInfos) })
            .then((data) => {
              debugLog(this.dbg, '>>> upsertLeadCore() Update - data ' + JSON.stringify(data));
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> upsertLeadCore() Update - error ' + error);
            });
          debugLog(this.dbg, '>>> update Lead() doApexEvent upsertLeadCore end');
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
          if (this.companyInfos.countryCode == 'LU') {
            otherChecks = this.checkLuVATModulo(field);
            field.hasError = !otherChecks;
          }
          //For BE and LU, the check has to be done only if VAT number starts with country code
          if (field.value.startsWith(this.companyInfos.countryCode))
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

  checkDataQty() {
    debugLog(this.dbg, 'checkDataQty *** START *** ');
    let isQtyOK = false;
    // Check if sufficient datas have been filled according to current step
    switch (this.currentStep) {
      case '1': //TODO temporary bypass
      case '2': //TODO temporary bypass
      case '3': //TODO temporary bypass
      case '4': //TODO temporary bypass
      case '7': //TODO temporary bypass
        isQtyOK = true;
        break;
    }
    if (this.cs) {
      isQtyOK = true;
    }
    debugLog(this.dbg, 'checkDataQty - isQtyOK = ' + isQtyOK + ' for step ' + this.currentStep);
    return isQtyOK;
  }

  convertLead() {
    let conversionParams =
      '{"leadId": "' +
      this.companyInfos.leadId +
      '", "countryCode": "' +
      this.country +
      '", "solution": "' +
      this.solution +
      '", "scope": "' +
      this.scope +
      '", "enterpriseNb": "' +
      this.companyInfos.enterpriseNb +
      '", "email": "' +
      this.companyInfos.email +
      '", "iban": "' +
      this.companyInfos.IBAN +
      '", "bic": "' +
      this.companyInfos.BIC +
      '", "benefits": "' +
      this.erfiBenefits +
      '", "cardType": "' +
      this.erfiCardType +
      '", "additionalProducts": "' +
      this.additionalSelectedProducts +
      '"}';
    doApexEvent({ operationName: 'convertLead', operationParams: conversionParams })
      .then((data) => {
        this.isConvertedLead = true;
        debugLog(this.dbg, '>>> convertLead() Convert - data ' + JSON.stringify(data));
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> convertLead() - error ' + error);
      });
  }

  // handlePromoCode(event) {
  //   this.hasPromoCode = event.detail;
  //   debugLog(this.dbg, 'handlePromoCode - hasPromoCode = ' + this.hasPromoCode);
  // }

  // handlehasNoBillingAccount(event) {
  //   this.hasNoBillingAccount = event.detail == 'true';
  // }

  // updateOpportunity() {
  //   doApexEvent({
  //     operationName: 'updateOpportunity',
  //     operationParams:
  //       this.companyInfos.leadId + '|' + this.companyInfos.promoCode + '|' + this.solution + '|' + this.scope
  //   })
  //     .then((data) => {
  //       debugLog(this.dbg, '>>> updateOpportunity() - data ' + JSON.stringify(data));
  //     })
  //     .catch((error) => {
  //       debugLog(this.dbg, '>>> updateOpportunity() - error ' + error);
  //     });
  // }

  // handleSameAsMainContact(event) {
  //   debugLog(this.dbg, 'handleSameAsMainContact event.detail = ' + event.detail);

  //   const fieldMapping = {
  //     refundContactId: 'contactId',
  //     refundSalutation: 'salutation',
  //     refundFirstName: 'firstName',
  //     refundLastName: 'lastName',
  //     refundLang: 'lang',
  //     refundContactPhone: 'contactPhone',
  //     refundMobile: 'mobile',
  //     refundRole: 'role',
  //     refundEmail: 'email',
  //     refundFax: 'fax'
  //   };
  //   let fieldList = this.template.querySelectorAll('[data-group="refundContact"]');
  //   debugLog(this.dbg, 'handleSameAsMainContact - fieldList length = ' + fieldList.length);

  //   if (event.detail) {
  //     //If checkbox is checked
  //     debugLog(this.dbg, 'handleSameAsMainContact finCenterInfos = ' + JSON.stringify(this.finCenterInfos));
  //     initFields(fieldList, this.companyInfos, true, fieldMapping, this.finCenterInfos);
  //     // Set picklists
  //     this.picklistGroup.refundSalutation = JSON.parse(JSON.stringify(this.picklistGroup.salutation));
  //     this.picklistGroup.refundLang = JSON.parse(JSON.stringify(this.picklistGroup.lang));
  //     this.picklistGroup.refundRole = JSON.parse(JSON.stringify(this.picklistGroup.role));
  //     debugLog(
  //       this.dbg,
  //       'handleSameAsMainContact this.picklistGroup.refundSalutation ' +
  //         JSON.stringify(this.picklistGroup.refundSalutation)
  //     );
  //   } else {
  //     eraseFieldsAndEnable(fieldList);
  //     // unselect picklists
  //     resetPicklist([
  //       this.picklistGroup.refundSalutation,
  //       this.picklistGroup.refundLang,
  //       this.picklistGroup.refundRole
  //     ]);
  //   }
  //   this.savFinCenterBtnDisabled = false;
  //   debugLog(this.dbg, 'handleSameAsMainContact END ');
  // }

  // handleCopyMainAddress(event) {
  //   debugLog(this.dbg, 'handleCopyMainAddress ***Start*** ');
  //   const fieldMapping = {
  //     refundAddress: 'address',
  //     refundPostalCode: 'postalCode',
  //     refundCity: 'city',
  //     refundCountry: 'country'
  //   };
  //   let fieldList = this.template.querySelectorAll('[data-group="refundAddress"]');
  //   if (event.detail) {
  //     //If checkbox is checked
  //     initFields(fieldList, this.companyInfos, true, fieldMapping, this.finCenterInfos);
  //     this.picklistGroup.refundCountry = JSON.parse(JSON.stringify(this.picklistGroup.country));
  //   } else {
  //     eraseFieldsAndEnable(fieldList);
  //     resetPicklist([this.picklistGroup.refundCountry]);
  //   }
  //   this.savFinCenterBtnDisabled = false;
  //   debugLog(this.dbg, 'handleCopyMainAddress ***END*** ');
  // }

  // handleFinCenterInfos(event) {
  //   //TODO voir si factorisable?
  //   debugLog(this.dbg, 'handleFinCenterInfos ***Start*** ');
  //   debugLog(this.dbg, 'handleFinCenterInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value);
  //   this.finCenterInfos[event.detail.field] = event.detail.value;

  //   // set picklist to the right option
  //   if (event.detail.picklist) {
  //     this.picklistGroup[event.detail.field] = initPicklistValue(
  //       this.picklistGroup[event.detail.field],
  //       event.detail.value
  //     );
  //     debugLog(
  //       this.dbg,
  //       'handleFinCenterInfos new picklist value: ' + JSON.stringify(this.picklistGroup[event.detail.field])
  //     );
  //   }

  //   // Check IBAN
  //   if (event.detail.field.startsWith('iban')) {
  //     debugLog(this.dbg, '>>> getBIC() - this.finCenterInfos iban ' + this.finCenterInfos[event.detail.field]);
  //     this.finCenterInfos.bankAccountSFId = ''; // In order to create a new bank account (webform offer process)
  //     if (
  //       this.finCenterInfos[event.detail.field] &&
  //       this.finCenterInfos[event.detail.field].trim().substring(0, 2).toUpperCase() != this.companyInfos.countryCode
  //     ) {
  //       debugLog(this.dbg, '>>> getBIC() - error  country different ');
  //       this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban_country, 'error');
  //       this.isValidIBAN = false;
  //       this.finCenterInfos[event.detail.field] = '';
  //     } else {
  //       let accountType = event.detail.field == 'ibanBilling' ? 'Billing' : '';
  //       this.checkBankAccount(this.finCenterInfos[event.detail.field], accountType);
  //     }
  //     debugLog(this.dbg, 'handleFinCenterInfos -- this.isValidIBAN: ' + this.isValidIBAN);
  //   }

  //   // Check city according to postalCode
  //   if (
  //     (event.detail.field === 'refundPostalCode' || event.detail.field === 'refundCity') &&
  //     this.finCenterInfos.refundPostalCode &&
  //     this.finCenterInfos.refundCity
  //   ) {
  //     this.checkCity(
  //       this.finCenterInfos.refundCity,
  //       this.finCenterInfos.refundPostalCode,
  //       this.finCenterInfos,
  //       'refundCity'
  //     );
  //   }

  //   this.savFinCenterBtnDisabled = false;
  //   debugLog(this.dbg, 'handleFinCenterInfos ***END*** ');
  // }

  // async checkBankAccount(ibanNb, accountType) {
  //   debugLog(this.dbg, '>>> checkBankAccount() - check iban ' + ibanNb + ' -> ' + accountType);
  //   if (ibanNb) {
  //     await getBIC({ iban: ibanNb.trim() })
  //       .then((data) => {
  //         debugLog(this.dbg, '>>> getBIC() - data ' + data);
  //         const response = JSON.parse(data);
  //         this.isValidIBAN = response.valid;
  //         if (this.isValidIBAN) {
  //           if (accountType != 'Billing') accountType = '';
  //           this.finCenterInfos['bic' + accountType] = this.checkIBAN = response.bankData.bic;
  //           this.finCenterInfos['bankName' + accountType] = response.bankData.name;
  //         } else {
  //           this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, 'error');
  //         }
  //       })
  //       .catch((error) => {
  //         debugLog(this.dbg, '>>> getBIC() - error ' + error);
  //       });
  //   }
  //   debugLog(this.dbg, 'checkBankAccount ***END*** ');
  // }

  // async saveFinCenter(event) {
  //   debugLog(this.dbg, 'saveFinCenter ***START*** ');
  //   let finCenter = this.finCenterInfos;
  //   debugLog(this.dbg, 'saveFinCenter -- this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));
  //   debugLog(
  //     this.dbg,
  //     'saveFinCenter -- (this.companyInfos.finCentersList.length + 1): ' +
  //       (this.companyInfos.finCentersList.length + 1)
  //   );

  //   if (finCenter.iban && finCenter.iban.includes('*')) this.isValidIBAN = true; // Set IBAN to valid if anonymized (it won't be modified in SF then)

  //   // if(!this.isValidIBAN) this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, "error");
  //   if (!this.isValidIBAN) await this.checkBankAccount(finCenter.iban, ''); // Do one more check in order to cover one specific use case
  //   if (finCenter.ibanBilling) await this.checkBankAccount(finCenter.ibanBilling, 'Billing');

  //   let checkFields = checkRequiredFields(
  //     this.template.querySelectorAll('[data-group^="refund"]'),
  //     this.labels.lb_err_msg_required_field
  //   );
  //   if (this.isValidIBAN && checkFields) {
  //     debugLog(this.dbg, 'saveFinCenter -- finCenter.name: ' + finCenter.name);
  //     let finCenterNum = !finCenter.finCenterId ? this.getFinCenterId() : finCenter.finCenterId;
  //     finCenter.name = finCenter.name
  //       ? finCenter.name.trim()
  //       : this.companyInfos.legalName + ' (' + finCenterNum + ')';
  //     debugLog(this.dbg, 'saveFinCenter -- finCenter.name2: ' + finCenter.name);
  //     finCenter.contact = finCenter.refundFirstName + ' ' + finCenter.refundLastName;
  //     finCenter.fullAddress = finCenter.refundAddress + ', ' + finCenter.refundPostalCode + ' ' + finCenter.refundCity;

  //     debugLog(this.dbg, 'saveFinCenter -- this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));

  //     // Reorder finCenter columns to adjust datatable display
  //     let finCenterReorderedCols = {
  //       name: finCenter.name,
  //       contact: finCenter.contact,
  //       fullAddress: finCenter.fullAddress,
  //       iban: finCenter.iban.toUpperCase(),
  //       bic: finCenter.bic,
  //       bankName: finCenter.bankName,
  //       ibanBilling: finCenter.ibanBilling?.toUpperCase(),
  //       bicBilling: finCenter.bicBilling,
  //       bankNameBilling: finCenter.bankNameBilling,
  //       countryCode: this.country,
  //       refundContactId: finCenter.refundContactId,
  //       refundSalutation: finCenter.refundSalutation,
  //       refundFirstName: finCenter.refundFirstName,
  //       refundLastName: finCenter.refundLastName,
  //       refundLang: finCenter.refundLang,
  //       refundContactPhone: finCenter.refundContactPhone,
  //       refundMobile: finCenter.refundMobile,
  //       refundRole: finCenter.refundRole,
  //       refundEmail: finCenter.refundEmail,
  //       refundFax: finCenter.refundFax,
  //       refundAddress: finCenter.refundAddress,
  //       refundPostalCode: finCenter.refundPostalCode,
  //       refundCity: finCenter.refundCity,
  //       refundCountry: finCenter.refundCountry,
  //       finCenterId: finCenter.finCenterId,
  //       rowIndex: finCenter.rowIndex,
  //       finCenterSFId: finCenter.finCenterSFId,
  //       finCenterAccountSFId: finCenter.finCenterAccountSFId,
  //       bankAccountSFId: finCenter.bankAccountSFId
  //     };

  //     finCenter = finCenterReorderedCols;
  //     if (finCenter.finCenterSFId) finCenter.noDelete = true; // to hide delete button in data table

  //     debugLog(this.dbg, 'saveFinCenter -- before ins or upd: finCenter.finCenterId =  ' + finCenter.finCenterId);
  //     if (finCenter.finCenterId) {
  //       // case existing fin center, then update
  //       debugLog(this.dbg, 'saveFinCenter Update');

  //       const finCenterIndex = this.companyInfos.finCentersList.findIndex(
  //         (fc) => fc.finCenterId === finCenter.finCenterId
  //       );
  //       this.companyInfos.finCentersList.splice(finCenterIndex, 1, finCenter);
  //     } else {
  //       // case new fin center, then insert
  //       debugLog(this.dbg, 'saveFinCenter Insert');

  //       //Set finCenterId
  //       finCenter.finCenterId = this.getFinCenterId();
  //       debugLog(this.dbg, 'saveFinCenter -- before ins: finCenter.finCenterId =  ' + finCenter.finCenterId);

  //       this.companyInfos.finCentersList.push(JSON.parse(JSON.stringify(finCenter)));
  //       this.finCenterInfos = JSON.parse(JSON.stringify(finCenter));
  //       this.setRowIndex(this.finCenterInfos, this.companyInfos.finCentersList, 'finCenterId');
  //       debugLog(this.dbg, 'saveFinCenter Insert done  ');
  //     }
  //     this.setFinCenterpicklist();
  //     this.showToast(this.labels.lb_success, this.labels.lb_msg_update_success, 'success');
  //     this.savFinCenterBtnDisabled = true;
  //     this.template.querySelector('[data-id="finCentersList"]').scrollIntoView();
  //     this.showFinCenterdetails = false;
  //   }

  //   debugLog(this.dbg, 'saveFinCenter  -- ***END***');
  // }

  // // TODO factorisable: getItemId(objList)
  // getFinCenterId() {
  //   let finCenterIdList = this.companyInfos.finCentersList.map((finCenter) => finCenter.finCenterId);
  //   return finCenterIdList.length === 0 ? 1 : Math.max(...finCenterIdList) + 1;
  // }

  // setFinCenterpicklist() {
  //   if (this.hasMultipleFinCenter) {
  //     this.picklistGroup.finCenterId = [{ key: '', value: '...', hidden: true }];
  //     this.companyInfos.finCentersList.forEach((elem) =>
  //       this.picklistGroup.finCenterId.push({
  //         key: elem.finCenterId,
  //         value: elem.name
  //       })
  //     );
  //   }
  //   debugLog(
  //     this.dbg,
  //     'setFinCenterpicklist -- this.picklistGroup.finCenterId = ' + JSON.stringify(this.picklistGroup.finCenterId)
  //   );
  // }

  // newFinCenter() {
  //   debugLog(this.dbg, 'newFinCenter - START');
  //   this.showFinCenterdetails = true;
  //   this.finCenterInfos = {};
  //   let finCenter = this.finCenterInfos; // finCenter & pkList are alias to make code less verbose
  //   let pkList = this.picklistGroup;

  //   this.template.querySelectorAll('[data-group="refundCbx"]').forEach((cb) => (cb.isChecked = false));
  //   eraseFieldsAndEnable(this.template.querySelectorAll('[data-group="refundAddress"], [data-group="refundContact"]'));
  //   resetPicklist([pkList.refundSalutation, pkList.refundLang, pkList.refundRole, pkList.refundCountry]);

  //   finCenter.refundSalutation = finCenter.refundLang = finCenter.refundRole = finCenter.refundCountry = '';
  //   debugLog(this.dbg, 'newFinCenter - before scrollIntoView');
  //   this.template.querySelector('[data-id="ibanTitle"]').scrollIntoView();
  //   debugLog(this.dbg, 'newFinCenter - END');
  // }

  // handleEditFinCenter(event) {
  //   debugLog(this.dbg, 'handleEditFinCenter - ***Start*** ');
  //   this.isReadOnlyEditable = false;
  //   this.showFinCenterdetails = true;

  //   let fieldList = this.template.querySelectorAll(
  //     '[data-group="refundAddress"], [data-group="refundContact"], [data-id="iban"]'
  //   );
  //   let finCentersList = this.companyInfos.finCentersList;

  //   debugLog(
  //     this.dbg,
  //     'handleEditFinCenter - Row to be displayed: ' + JSON.stringify(finCentersList[event.detail.value])
  //   );
  //   initFields(fieldList, finCentersList[event.detail.value], this.isReadOnly);
  //   // this.finCenterInfos = finCentersList[event.detail.value];
  //   // Init non displayed field
  //   this.finCenterInfos.rowIndex = event.detail.value;
  //   this.finCenterInfos.finCenterId = event.detail.value + 1;
  //   this.finCenterInfos.name = finCentersList[event.detail.value].name;
  //   this.finCenterInfos.finCenterSFId = finCentersList[event.detail.value].finCenterSFId;
  //   this.finCenterInfos.finCenterAccountSFId = finCentersList[event.detail.value].finCenterAccountSFId;
  //   this.finCenterInfos.bankAccountSFId = finCentersList[event.detail.value].bankAccountSFId;
  //   debugLog(this.dbg, 'handleEditFinCenter - this.finCenterInfos: ' + JSON.stringify(this.finCenterInfos));

  //   // Set picklists displayed values
  //   initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist'));

  //   debugLog(this.dbg, 'handleEditFinCenter *** END *** ');
  // }

  // handleDeleteFinCenter(event) {
  //   this.companyInfos.finCentersList.splice(event.detail.value, 1);
  //   this.template.querySelectorAll('[data-group="refundCbx"]').forEach((cb) => (cb.isChecked = false));
  //   this.setRowIndex(this.finCenterInfos, this.companyInfos.finCentersList, 'finCenterId');
  //   this.newFinCenter();
  //   this.setFinCenterpicklist();
  // }

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

  // initTermsAndConditions() {
  //   debugLog(this.dbg, '>>> initTermsAndConditions() - lang ' + this.lang);
  //   getTermsAndConditions({
  //     country: this.companyInfos.countryCode,
  //     lang: this.lang,
  //     solution: this.solution,
  //     scope: this.scope
  //   })
  //     .then((data) => {
  //       debugLog(this.dbg, '>>> initTermsAndConditions() - data ' + JSON.stringify(data));
  //       debugLog(this.dbg, '>>> initTermsAndConditions() - version ' + data.tcVersion);
  //       this.termsAndConditions = data;
  //     })
  //     .catch((error) => {
  //       debugLog(this.dbg, '>>> initTermsAndConditions() - error ' + error);
  //     });
  // }

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
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
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

  getCrossSellingMsg() {
    debugLog(
      this.dbg,
      '//// cross Selling => ' +
        this.cs +
        '/existingClient => ' +
        this.existingClient +
        '/ongoingOpp =>' +
        this.ongoingOpp +
        '/invalidScope =>' +
        this.invalidScope +
        '/invalidProduct =>' +
        this.invalidProduct +
        '/existingAccount =>' +
        this.existingAccount +
        '/activeProduct =>' +
        this.activeProduct
    );
    //console.log('this.stepsCount.toString() ' + this.stepsCount.toString());
    if (!this.cs || this.showSpinner) return undefined;

    // if invalid scope or invalid product code or invalid crn
    if (!this.existingAccount || this.invalidScope || this.invalidProduct)
      return this.labels.lb_err_msg_not_existing_company_cs;

    // if active contract of the specified product
    if (this.activeProduct) return this.labels.lb_err_msg_existing_product_cs;

    // if no active contract of tje specifierd product and has open oppty
    if (this.ongoingOpp) return this.labels.lb_err_msg_opp_in_prog;

    return undefined;
  }

  get crossSellingMsg() {
    return this.getCrossSellingMsg();
  }

  get crossSellingMsg2() {
    let msg = this.getCrossSellingMsg();
    if (msg == this.labels.lb_err_msg_not_existing_company_cs) return this.labels.lb_err_msg_contact_us;
    return undefined;
  }
}