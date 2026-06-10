/**
 * Created by Saad on 02/06/2023.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getFinancialCenterInfos from '@salesforce/apex/ManageFinancialCenter.getFinancialCenterInfos';
import updateFinancialCenter from '@salesforce/apex/ManageFinancialCenter.updateFinancialCenter';
import createFinancialCenter from '@salesforce/apex/ManageFinancialCenter.createFinancialCenter';
import getMainContactInfos from '@salesforce/apex/ManageFinancialCenter.getMainContactInfos';
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';
import getFcStoresInfos from '@salesforce/apex/ManageFinancialCenter.getFcStoresInfos';

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

export default class ErPortalFinancialCenter extends LightningElement {
  currentPageReference = null;
  urlStateParameters = null;

  @api key; // Parameter to get from the URL that contains an encrypted accountId
  @api country; // Parameter to be set in the builder for the page variation dedicated to the country
  @api lang; // Lang parameter get from url
  @api locale; // Locale parameter get from url
  @api solution; // Product parameter get from url
  @api dbg; // Debug mode (to enable logs display)
  @api id;
  // @api isFromWebOffer; // Parameter added when url is from quote web offer
  @api scope; // scope parameter get from url
  @api mode; // view or edit or new
  @api parentCRN;

  accountId;
  financialCenterId;
  parentKey;

  showSpinner;
  isReadOnly;
  isReadOnlyEditable;
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
  bankInfoRequired = false;

  // Picklist values
  @track picklistGroup = {};
  @track companyInfos = {};
  @track storeInfos = {};

  @track financialConditions = [];
  @track storesListTableColumns;
  @track storesInfo = {};
  @track storesList = [];

  hasPromoCode;
  hasNoBillingAccount = true;
  isValidIBAN;
  savFinCenterBtnDisabled = true;
  showFinCenterdetails = true;

  @track tableLabels = {};

  subscription = null; // used for recaptcha component
  isRecaptchaSuccess;
  @wire(MessageContext)
  messageContext;

  // Store categories (Dependant values)
  @track categories = {};
  @track categorieItems = [];
  @track chosenCategories = [];

  stepsCount = 0;
  showHeader;
  @track stepList = [];

  showAddFinCenter = true;
  hasCheckedEnterpriseNb = true;
  mainInfoChanged = false;
  contactChanged = false;
  crn;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.urlStateParameters = currentPageReference.state;
      this.setParametersBasedOnUrl();
    }
  }

  // Init properties from URL params
  setParametersBasedOnUrl() {
    this.key = this.urlStateParameters.id;
    this.lang = this.urlStateParameters.language.substring(0, 2).toUpperCase();
    this.scope = this.urlStateParameters.scope;
    this.dbg = this.urlStateParameters.dbg === 'true' ? true : false;
    this.companyInfos.enterpriseNb = this.urlStateParameters.crn;
    this.crn = this.urlStateParameters.crn;
    this.country = this.urlStateParameters.bu;
    this.companyInfos.bu = this.urlStateParameters.bu;
    this.mode = this.urlStateParameters.mode;
    this.locale = this.urlStateParameters.language;
    this.financialCenterId = this.urlStateParameters.id;
    this.parentCRN = this.urlStateParameters.parentcrn;
    if (this.urlStateParameters.parentcrn != null) {
      this.companyInfos.enterpriseNb = this.urlStateParameters.parentcrn;
    }
    this.parentkey = this.urlStateParameters.parentid;
    this.companyInfos.country = this.urlStateParameters.defaultcountry;
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

        if (this.labels.lb_steps_onboarding != null) {
          let stepCounter = 0;
          this.stepsCount = this.labels.lb_steps_onboarding.split('|').length;
          this.labels.lb_steps_onboarding.split('|').forEach((step) => {
            stepCounter++;
            this.stepList.push({ nb: stepCounter.toString(), label: step });
          });
          this.showHeader = true;
        }

        debugLog(this.dbg, '>>> connectedCallback() - this.isWebOffer ' + this.isWebOffer);

        if (this.financialCenterId) {
          getFinancialCenterInfos({ financialCenterId: this.financialCenterId })
            .then((data) => {
              debugLog(this.dbg, '>>> getCompanyInfosCore() - data ' + JSON.stringify(data));

              Object.keys(data).forEach((key) => {
                this.companyInfos[key] = data[key];
              });

              this.accountId = data['accountId'];

              getFcStoresInfos({ fcId: this.financialCenterId, locale: this.locale })
                .then((data) => {
                  debugLog(this.dbg, '>>> getFinCentersInfos() - data ' + JSON.stringify(data));
                  data.forEach((elem, index) => {
                    let store = {};
                    store.noDelete = true; // to hide delete button in data table
                    Object.keys(elem).forEach((key) => {
                      store[key] = elem[key];
                    });
                    store.storeId = index + 1;
                    store.hasLink = true;
                    store.href = this.getStoreUrl(store.storeSFId);
                    this.storesList.push(store);
                  });
                  if (this.storesList.length > 0) {
                    this.storesInfo = JSON.parse(JSON.stringify(this.storesList[0]));
                    this.setRowIndex(this.storesInfo, this.storesList, 'storeId');
                  }
                  this.hasCheckedEnterpriseNb = true;
                })
                .catch((error) => {
                  debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
                });
            })
            .catch((error) => {
              this.expiredQuote = true;
              this.showSpinner = false;
              debugLog(this.dbg, '>>> getCompanyInfosCore()1 - error ' + JSON.stringify(error));
            });
        }

        debugLog(true, '>>> connectedCallback() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);

        // Init store and terminal data tables headers
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getLabels() - error ' + error);
      });
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
          // if (this.companyInfos.countryCode == 'LU') {
          //   otherChecks = this.checkLuVATModulo(field);
          //   field.hasError = !otherChecks;
          // }
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

    this.mainInfoChanged = true;
  }

  get blockEdit() {
    return this.mode?.toLowerCase() == 'edit' || this.mode?.toLowerCase() == 'new' ? false : true;
  }

  get isEdit() {
    return this.mode?.toLowerCase() == 'edit' ? true : false;
  }

  get isNew() {
    return this.mode?.toLowerCase() == 'new' ? true : false;
  }

  get isView() {
    return this.mode?.toLowerCase() == 'view' ? true : false;
  }

  get bankInfoDisabled() {
    return this.mode?.toLowerCase() == 'new' ? false : true;
  }

  get isOvtMandatory() {
    return this.isERFI && this.mode.toLowerCase() == 'new' ? true : false;
  }

  get isERFI() {
    if (this.companyInfos.bu?.toLowerCase() == 'fi') {
      return true;
    }
  }

  get showStores() {
    if (this.scope?.toUpperCase() == 'M') {
      return true;
    } else {
      return false;
    }
  }

  handleEdit() {
    var url = new URL(window.location.href); // get current URL
    var params = new URLSearchParams(url.search); // get query parameters

    // if mode parameter is found and equals 'view'
    if (params.get('mode')?.toLowerCase() === 'view') {
      params.set('mode', 'edit'); // replace 'view' with 'edit'
      url.search = params.toString(); // update query parameters in the URL
      window.location.href = url.toString(); // redirect to the new URL
    }
  }

  handleCancelEdit() {
    var url = new URL(window.location.href); // get current URL
    var params = new URLSearchParams(url.search); // get query parameters

    // if mode parameter is found and equals 'view'
    if (params.get('mode')?.toLowerCase() === 'edit') {
      params.set('mode', 'view'); // replace 'view' with 'edit'
      url.search = params.toString(); // update query parameters in the URL
      window.location.href = url.toString(); // redirect to the new URL
    }
  }

  handleCancelNew() {
    var url = new URL(window.location.href); // get current URL
    var params = new URLSearchParams(url.search); // get query parameters

    var currentURL = window.location.href;

    // Create a dummy anchor element
    var anchor = document.createElement('a');
    anchor.href = currentURL;

    // Extract the base URL from the dummy anchor element
    var baseURL = anchor.protocol + '//' + anchor.hostname;

    let newURL =
      baseURL +
      '/s/manage-structure?crn=' +
      this.companyInfos.enterpriseNb +
      '&scope=' +
      this.scope +
      '&bu=' +
      this.country +
      '&id=' +
      this.parentkey;

    window.location.href = newURL; // redirect to the new URL
  }

  handleSaveNew() {
    /*let params =
              JSON.stringify(this.companyInfos) +
              '|' +
              this.scope;*/

    //doApexEvent({ operationName: 'createFinancialCenter', operationParams: params })
    let inputFields = [...this.template.querySelectorAll('c-er-portal-input')];

    let checkFields =
      checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && this.validateFieldsFormat(inputFields);

    if (checkFields) {
      this.showSpinner = true;
      createFinancialCenter({ companyInfosJSON: JSON.stringify(this.companyInfos), scope: this.scope })
        .then((data) => {
          debugLog(this.dbg, '>>> updateFinancialCenter() - success ');
          this.showSpinner = false;
          this.handleCancelNew();
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> updateFinancialCenter() - error ' + JSON.stringify(error));
          this.showSpinner = false;
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_insert, 'error');
        });

      this.contactChanged = false;
      this.mainInfoChanged = false;
    }
  }

  handleCopyContactInfos(event) {
    debugLog(this.dbg, 'handleCopyContactInfos *** START *** ');
    if (event.detail) {
      this.showSpinner = true;
      getMainContactInfos({ crn: this.companyInfos.enterpriseNb })
        .then((data) => {
          debugLog(this.dbg, '>>> handleCopyContactInfos() - success ');
          this.showSpinner = false;
          let result = JSON.parse(data);
          this.companyInfos.firstName = result['FirstName'];
          this.companyInfos.lastName = result['LastName'];
          this.companyInfos.email = result['Email'];
          this.companyInfos.contactPhone = result['Phone'];
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> handleCopyContactInfos() - error ' + JSON.stringify(error));
          this.showSpinner = false;
        });
    } else {
      this.companyInfos.firstName = '';
      this.companyInfos.lastName = '';
      this.companyInfos.email = '';
      this.companyInfos.contactPhone = '';
    }
  }

  switchLanguage(lang) {
    this.lang = lang;
    this.labels = {
      ...this.labelsAllLangs[this.lang],
      ...this.labelsAllLangs['All']
    };

    this.storesListTableColumns = {
      name: this.labels.lb_store,
      storeStatus: this.labels.lb_store_status,
      storeContactFullName: this.labels.lb_contact,
      fullAddress: this.labels.lb_step2b_store_address
    };

    this.tableLabels.lb_edit = this.labels.lb_edit;
    this.tableLabels.lb_delete = this.labels.lb_delete;

    this.setPicklistInfos();
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
        this.picklistGroup.invoicingMethod = formatPicklist(data.pk_invoicing_method);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
      });
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

  newStoreOnboarding() {
    // add store
    let url = document.location.href;
    let urlParts = url.split('/');

    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-store?mode=new&parentid=' +
      this.financialCenterId +
      '&bu=' +
      this.country +
      '&language=' +
      this.lang;

    window.location.href = redirectionUrl;
  }

  getStoreUrl(storeId) {
    // Store link
    let url = document.location.href;
    let urlParts = url.split('/');

    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-store?mode=view&parentid=' +
      this.financialCenterId +
      '&id=' +
      storeId +
      '&bu=' +
      this.country +
      '&language=' +
      this.lang +
      '&scope=' +
      this.scope;
      return redirectionUrl;
    }

  handleContactInfos(event) {
    this.companyInfos[event.detail.field] = event.detail.value;

    if (event.detail.picklist) {
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
    }

    this.contactChanged = true;
  }

  handleSaveEdit() {
    let inputFields = [...this.template.querySelectorAll('c-er-portal-input')];

    let checkFields =
      checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && this.validateFieldsFormat(inputFields);
    if (checkFields) {
      this.showSpinner = true;
      updateFinancialCenter({
        updatedContact: this.contactChanged,
        updatedMainInfos: this.mainInfoChanged,
        companyInfosJSON: JSON.stringify(this.companyInfos),
        financialCenterId: this.financialCenterId
      })
        .then((data) => {
          debugLog(this.dbg, '>>> updateFinancialCenter() - success ');
          this.showSpinner = false;
          this.handleCancelNew();
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> updateFinancialCenter() - error ' + JSON.stringify(error));
          this.showSpinner = false;
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_update, 'error');
        });

      this.contactChanged = false;
      this.mainInfoChanged = false;
    }
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