/**
 * Created by Saad on 02/06/2023.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getCompanyInfos from '@salesforce/apex/GenericWithoutSharing.getCompanyInfos';
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';
import decrypt from '@salesforce/apex/GenericWithoutSharing.decrypt';
import getFinCentersInfosByCRN from '@salesforce/apex/ManageFinancialCenter.getFinCentersInfosByCRN';

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

export default class ErPortalHome extends LightningElement {
    currentPageReference = null;
    urlStateParameters = null;

    @api key; // Parameter to get from the URL that contains an encrypted accountId
    @api country; // Parameter to be set in the builder for the page variation dedicated to the country
    @api lang; // Lang parameter get from url
    @api locale; // Locale parameter get from url
    @api solution; // Product parameter get from url
    @api dbg; // Debug mode (to enable logs display)
    // @api isFromWebOffer; // Parameter added when url is from quote web offer
    @api scope; // scope parameter get from url

    accountId;

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

    // Picklist values
    @track picklistGroup = {};
    @track companyInfos = {};
    @track storeInfos = {};

    @track financialConditions = [];
    @track finCenterInfos = {};
    @track finCentersList = [];


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
    @track finCentersListTableColumns = {};

    showAddFinCenter = true;
    hasCheckedEnterpriseNb = true;
    hasFinCenter = true;
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

          if(this.crn) {
              //decrypt({ encryptedText : this.key})
              //.then((data) => {
              // this.accountId = data;
              getCompanyInfos({ crn: this.companyInfos.enterpriseNb })
              .then((data) => {
                debugLog(this.dbg, '>>> getCompanyInfosCore() - data ' + JSON.stringify(data));
                this.companyInfos = {};
                this.companyInfos.enterpriseNb = this.crn;
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

              getFinCentersInfosByCRN({ crn: this.crn, scope: this.scope })
              .then((data) => {
                debugLog(this.dbg, '>>> getFinCentersInfos() - data ' + JSON.stringify(data));
                data.forEach((elem, index) => {
                  let finCenter = {};
                  finCenter.noDelete = true; // to hide delete button in data table
                  Object.keys(elem).forEach((key) => {
                    finCenter[key] = elem[key];
                  });
                  finCenter.finCenterId = index + 1;
                  finCenter.hasLink = true;
                  finCenter.href = this.getFinCenterUrl(finCenter['finCenterSFId']);
                  this.finCentersList.push(finCenter);
                });
                if (this.finCentersList.length > 0) {
                  this.finCenterInfos = JSON.parse(JSON.stringify(this.finCentersList[0]));
                  this.setRowIndex(this.finCenterInfos, this.finCentersList, 'finCenterId');
                }
                this.hasCheckedEnterpriseNb = true;
              /*})
              .catch((error) => {
                debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
              });*/
              })
              .catch((error) => {
                  debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
              })
          }


          debugLog(true, '>>> connectedCallback() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);

          // Init store and terminal data tables headers
          this.finCentersListTableColumns = {
            name: this.labels.lb_step2_fin_center,
            contact: this.labels.lb_step2_contact,
            invoicingAddress: this.labels.lb_step2b_store_address,
            iban: this.labels.lb_step2_iban
          };
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

    switchLanguage(lang) {
      this.lang = lang;
      this.labels = {
        ...this.labelsAllLangs[this.lang],
        ...this.labelsAllLangs['All']
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

    newFinCenter(){
        var url = new URL(window.location.href); // get current URL
        var params = new URLSearchParams(url.search); // get query parameters

        var currentURL = window.location.href;

        // Create a dummy anchor element
        var anchor = document.createElement('a');
        anchor.href = currentURL;

        // Extract the base URL from the dummy anchor element
        var baseURL = anchor.protocol + '//' + anchor.hostname;

        let newURL = baseURL + '/s/manage-fc?mode=new&parentcrn='
        + this.crn
        + '&scope='
        + this.scope
        + '&bu='
        + this.country
        + '&parentid='
        + this.key
        + '&defaultcountry='
        + this.companyInfos.country;

        window.location.href = newURL // redirect to the new URL
    }

    getFinCenterUrl(id){
        var url = new URL(window.location.href); // get current URL
        var params = new URLSearchParams(url.search); // get query parameters

        var currentURL = window.location.href;

        // Create a dummy anchor element
        var anchor = document.createElement('a');
        anchor.href = currentURL;

        // Extract the base URL from the dummy anchor element
        var baseURL = anchor.protocol + '//' + anchor.hostname;

        return baseURL + '/s/manage-fc?mode=view&parentid='
        + this.key
        + '&id='
        + id
        + '&scope='
        + this.scope
        + '&bu='
        + this.country;
    }
}