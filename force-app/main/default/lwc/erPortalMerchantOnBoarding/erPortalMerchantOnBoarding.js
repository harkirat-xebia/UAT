/*************************************************************************************
LWC Name:     ErPortalMerchantOnBoarding
Version:      1.0
Created Date: 08/08/2022
Purpose:      Merchant onboarding Auto enrollment.

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           08/08/2022  Initial (Auto enrollment Project)
*************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';

// Apex methods
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import checkCity from '@salesforce/apex/APER30_AutoEnrollment_Management.checkCity';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';
import getAcceptorModels from '@salesforce/apex/APER30_AutoEnrollment_Management.getAcceptorModels';
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
import checkExistingAcceptor from '@salesforce/apex/GenericWithoutSharing.checkExistingAcceptor';
import getOnBoardingDatas from '@salesforce/apex/GenericWithoutSharing.getOnBoardingDatas';

// Captcha resources
import { MessageContext, publish } from 'lightning/messageService';
import languageList from '@salesforce/messageChannel/Language_List__c';

// Misceleanous (toast messages, utils functions, platform evt)
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
  formatPicklist,
  initPicklistValue,
  initPicklistDisplay,
  resetPicklist,
  checkRequiredFields,
  initFields,
  validateFormat,
  isValidTID,
  debugLog,
  buildTemplate
} from 'c/erPortalUtils';

export default class ErPortalMerchantOnBoarding extends LightningElement {
  currentPageReference = null;
  urlStateParameters = null;

  @api country;
  @api lang;
  @api locale;
  @api solution;
  @api uniqueKeyId;
  @api version;
  @api dbg;

  @api picklistGroupInherit;
  @api labelsAllLangs;
  @api labels;
  @api isWebOffer;
  @track merchantInfos = {};
  @api merchantInfosInherit;
  @api currentStep;
  @api isReadOnly;
  @api companyInfos;
  @api storesListTableColumns;
  @api terminalsListTableColumns;
  @api merchantUsersListTableColumns;

  @track picklistGroup = {};

  scope = 'M'; // Merchant scope
  stepValidated;

  @wire(MessageContext)
  messageContext;

  //   showSpinner;
  isReadOnlyEditable;
  leadId;
  activatedAccount;
  hasContract;
  contractNbChecked;
  initCategoriesDone;

  showStoreDetails = true;
  savStoreBtnDisabled = true;
  savTerminalBtnDisabled = true;
  // showTerminalBlock;
  hideCreateTerminalBlock = true;
  mastercardOnlyProviders = [];
  isMIDChecked = true;
  lastMIDErrMsg;
  storeMandatoryFields = [];

  @track tableLabels = {};

  @track merchantUserInfos = {};
  @track storeInfos = {};
  terminalProvidersAndModels = {};

  // Store categories (Dependant values)
  @track categories = {};
  @track categorieItems = [];
  @track chosenCategories = [];
  @track previousCats = [];

  // Terms & conditions
  @track termsAndConditions = {};

  hasAcceptedConditions;

  onboardingEndMessage = '';
  isStepMainOnboarding = true;
  validateStoreStructure = false;
  isStepUsers;

  async connectedCallback() {
    debugLog(true, 'connectedCallback - *** Start ***');
    this.picklistGroup = JSON.parse(JSON.stringify(this.picklistGroupInherit));
    this.merchantInfos = JSON.parse(JSON.stringify(this.merchantInfosInherit));
    this.leadId = this.merchantInfos.leadId;
    this.mastercardOnlyProviders = this.labels.ctap_not_compatible_models.split('|');
    this.storeMandatoryFields = JSON.parse(this.labels.store_mandatory_fields);
    // debugLog(true, 'connectedCallback - picklistGroup: ' + JSON.stringify(this.picklistGroup));

    if (this.merchantInfos.storesList?.length > 0) {
      this.storeInfos = JSON.parse(JSON.stringify(this.merchantInfos.storesList[0]));
      this.storeInfos.terminalInfos = {};
      this.storeInfos.terminalInfos.rowIndex = 0;

      // Check if store structure is valid, in order to enable Validate button
      this.validateStoreStructure = true;
      this.merchantInfos.storesList.forEach((store) => {
        if (this.validateStoreStructure) {
          if (store.terminalsList?.length == 0) this.validateStoreStructure = false;
          if ((store.chosenCategories && store.chosenCategories.length == 0) || store.chosenCategories == undefined)
            this.validateStoreStructure = false;
        }
      });
    } else {
      debugLog(true, 'connectedCallback - this.merchantInfos1: ' + JSON.stringify(this.merchantInfos));
      this.merchantInfos.storesList = [];
      this.merchantInfos.storesList.push({
        name: '',
        fullAddress: '',
        finCenterName: '',
        finCenterId: 1
      });
      debugLog(true, 'connectedCallback - this.merchantInfos2: ' + JSON.stringify(this.merchantInfos));
    }

    // getEnterpriseInfos({
    //   enterpriseNb: null,
    //   country: this.country,
    //   lang: this.lang,
    //   uniqueKeyId: this.uniqueKeyId,
    //   userEmail: null
    // })
    //   .then((data) => {
    //     debugLog(this.dbg, '>>> getEnterpriseInfos()2 - data ' + JSON.stringify(data));
    //     this.merchantInfos = {};
    //     this.merchantInfos.storesList = [];
    //     this.merchantInfos.finCentersList = [];

    //     Object.keys(data).forEach((key) => {
    //       this.merchantInfos[key] = data[key];
    //     });

    //     getFinCentersInfos({
    //       accountId: this.merchantInfos.accountId
    //     })
    //       .then((data) => {
    //         debugLog(this.dbg, '>>> getFinCentersInfos() - accountId ' + this.merchantInfos.accountId);
    //         debugLog(this.dbg, '>>> getFinCentersInfos() - data ' + JSON.stringify(data));
    //         data.forEach((elem, index) => {
    //           let finCenter = {};
    //           finCenter.noDelete = true; // to hide delete button in data table
    //           Object.keys(elem).forEach((key) => {
    //             finCenter[key] = elem[key];
    //           });
    //           finCenter.finCenterId = index + 1;
    //           this.merchantInfos.finCentersList.push(finCenter);
    //         });
    //         debugLog(
    //           this.dbg,
    //           '>>> getFinCentersInfos() - this.merchantInfos.finCentersList.length ' +
    //             this.merchantInfos.finCentersList.length
    //         );

    //         debugLog(
    //           this.dbg,
    //           '>>> getFinCentersInfos() - this.merchantInfos.finCentersList ' +
    //             JSON.stringify(this.merchantInfos.finCentersList)
    //         );

    //         this.retrieveOnboardingDatas();
    //       })
    //       .catch((error) => {
    //         debugLog(this.dbg, '>>> getFinCentersInfos() - error ' + error);
    //       });
    //   })
    //   .catch((error) => {
    //     debugLog(this.dbg, '>>> getEnterpriseInfos() - error ' + JSON.stringify(error));
    //   });
  }

  retrieveOnboardingDatas() {
    debugLog(
      this.dbg,
      '>>> retrieveOnboardingDatas() - this.merchantInfos accountId - contractId: ' +
        this.merchantInfos.accountId +
        ' - ' +
        this.merchantInfos.contractId
    );
    getOnBoardingDatas({
      accountId: this.merchantInfos.accountId,
      contractId: this.merchantInfos.contractId
    }).then((data) => {
      debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.merchantInfos2 data: ' + JSON.stringify(data));
      Object.assign(this.merchantInfos, data); // merge objects
      this.initCompanyInfos();
      // this.merchantInfos.accountId = data.accountId;
      debugLog(this.dbg, '>>> retrieveOnboardingDatas() - this.merchantInfos2 ' + JSON.stringify(this.merchantInfos));

      // Populate data tables with empty records if no data yet (for the display)
      if (!this.hasStore) {
        this.merchantInfos.storesList.push({
          name: '',
          fullAddress: '',
          finCenterName: '',
          finCenterId: 1
        });
      } else {
        this.merchantInfos.storesList.forEach((store) => {
          debugLog(this.dbg, '>>> getOnBoardingDatas() - store ' + JSON.stringify(store));
        });
        // Init common chosenCategories with 1st store datas
        this.initCategories();
        debugLog(
          this.dbg,
          '>>> retrieveOnboardingDatas() - this.merchantInfos.storesList[0].chosenCategories ' +
            JSON.stringify(this.merchantInfos.storesList[0].chosenCategories)
        );
      }
      if (!this.hasMerchantUser) {
        this.merchantInfos.usersList = [];
        this.merchantInfos.usersList.push({
          userName: '',
          userEmail: '',
          contractNb: '',
          userId: 1
        });
        this.merchantUserInfos.userId = 1;
      }
      debugLog(
        this.dbg,
        '>>> retrieveOnboardingDatas() - this.chosenCategories ' + JSON.stringify(this.chosenCategories)
      );
    });
    // .catch((error) => { debugLog(this.dbg, ">>> retrieveOnboardingDatas() - error " + JSON.stringify(error)); });
  }

  // Initialise all the number of steps and their respective name
  get stepList() {
    return [
      {
        nb: '1',
        label: this.labels.lb_step1
      },
      {
        nb: '2',
        label: this.labels.lb_step2
      },
      {
        nb: '3',
        label: this.labels.lb_step3
      }
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
    return this.isStepFive;
  }

  get isEnableBack() {
    return !this.isStepMainOnboarding && this.currentStep != '8';
  }

  get isEnableFinish() {
    return this.isStepMainOnboarding || this.isStepUsers || ['3', '4', '6'].includes(this.currentStep);
  }

  get hasStore() {
    return this.merchantInfos.storesList.length > 0;
  }

  get isSectorPkListDisabled() {
    return !this.storeInfos.isFranchisee;
  }

  get hasMerchantUser() {
    return this.merchantInfos.usersList && this.merchantInfos.usersList.length > 0;
  }

  get hasFinCenter() {
    return this.merchantInfos.finCentersList.length > 0;
  }

  get hasMultipleFinCenter() {
    return this.merchantInfos.finCentersList.length > 1;
  }

  get isReadOnlyTerminals() {
    return this.isReadOnly || this.isWebOffer;
  }

  get isWebOffer() {
    return this.uniqueKeyId && !this.version; // to distinguish Web offer from Auto enrollment v2 (that also have a uniqueKeyId on Onboarding part)
  }

  get isReadOnlyPromoCode() {
    return this.isReadOnly || this.isWebOffer;
  }

  get createTerminalsBtnDisabled() {
    debugLog(this.dbg, '>>> createTerminalsBtnDisabled() - this.storeInfos.storeId ' + this.storeInfos.storeId);
    return !this.storeInfos.storeId;
  }

  get createCategoriesBtnDisabled() {
    debugLog(
      this.dbg,
      '>>> createCategoriesBtnDisabled() - this.merchantInfos.storesList.length ' + this.merchantInfos.storesList.length
    );
    return this.merchantInfos.storesList.length == 0;
  }

  get validateBtnDisabled() {
    return this.isStepMainOnboarding && !this.validateStoreStructure;
  }

  get hasReadOnlyPhysicalTerminal() {
    return this.storeInfos.hasReadOnlyPhysicalTerminal || this.storeInfos.isPhysicalAcceptorMastercard;
  }

  // get hasTerminal() {
  //   return this.storeInfos?.terminalsList.length > 0 && this.storeInfos?.terminalsList[0].terminalProvider !== ' ';
  // }

  setPicklistInfos() {
    getPicklistInfos({
      country: this.country,
      lang: this.lang,
      scope: this.scope
    })
      .then((data) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - data ' + JSON.stringify(data));

        // Set language picklist of the header first
        this.picklistGroup.uiLang = formatPicklist(data.pk_lang_list);
        this.picklistGroup.uiLang = initPicklistValue(this.picklistGroup.uiLang, this.lang);
        publish(this.messageContext, languageList, this.picklistGroup.uiLang);

        this.picklistGroup.country = formatPicklist(data.pk_country);
        this.picklistGroup.role = formatPicklist(data.pk_role);
        this.picklistGroup.lang = formatPicklist(data.pk_lang);
        this.picklistGroup.salutation = formatPicklist(data.pk_salutation);

        // Picklist for refund contact
        this.picklistGroup.refundSalutation = formatPicklist(data.pk_salutation);
        this.picklistGroup.refundLang = formatPicklist(data.pk_lang);
        this.picklistGroup.refundRole = formatPicklist(data.pk_role);
        this.picklistGroup.refundCountry = formatPicklist(data.pk_country);

        // Picklist for stores
        this.picklistGroup.storeCountry = formatPicklist(data.pk_country);
        this.picklistGroup.isFranchisee = formatPicklist(data.pk_yes_no);
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
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
      });
  }

  @api switchLanguage(lang) {
      this.lang = lang;
      this.labels = {
        ...this.labelsAllLangs[this.lang],
        ...this.labelsAllLangs['All']
      };
      this.tableLabels.lb_edit = this.labels.lb_edit;
      this.tableLabels.lb_delete = this.labels.lb_delete;


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
    }

  handleNext() {
    if (!this.isReadOnly) {
      this.validateStep();
    } else {
      this.stepValidated = true;
    }

    debugLog(this.dbg, 'handleNext, stepValidated: ' + this.stepValidated);
    if (this.stepValidated) {
      // TODO create separate methods for each step in order to lighten the code
      switch (this.currentStep) {
        case '3':
          debugLog(
            this.dbg,
            '>>> createStores() *** START *** storesList: ' + JSON.stringify(this.merchantInfos.storesList)
          );
          if (!this.isReadOnly) {
            this.merchantInfos.storesList.forEach((store) => {
              store.chosenCategories = JSON.parse(JSON.stringify(this.chosenCategories));
              store.categorieItemsIds = this.categorieItems.map((cat) => cat.id);
            }); // categorieItemsIds is used to delete previous categories selected for current solution
            debugLog(this.dbg, '>>> createStores() - before create: ' + JSON.stringify(this.merchantInfos.storesList));
            doApexEvent({
              operationName: 'createStores',
              operationParams: this.merchantInfos.leadId + '|' + JSON.stringify(this.merchantInfos.storesList)
            })
              .then((data) => {
                debugLog(this.dbg, '>>> createStores() - data ' + JSON.stringify(data));
                this.isStepMainOnboarding = true;
                this.currentStep = null;
                this.validateStoreStructure = true;
              })
              .catch((error) => {
                debugLog(this.dbg, '>>> createStores() - error ' + error);
                this.validateStoreStructure = false;
              });
          }

          break;

        case '4':
          if (this.isMIDChecked) {
            // Save specific terminal flags at store level
            this.merchantInfos.storesList.forEach((store) => {
              if (store.storeId == this.storeInfos.storeId) {
                store.mid = this.storeInfos.mid;
                store.mid2 = this.storeInfos.mid2;
                store.subMid = this.storeInfos.subMid;
                store.subMid2 = this.storeInfos.subMid2;
                store.midCtap = this.storeInfos.midCtap;
                store.hasOnlineStore = this.storeInfos.hasOnlineStore;
                store.isOnlineStoreMastercard = this.storeInfos.isOnlineStoreMastercard;
                store.hasAgregator = this.storeInfos.hasAgregator;
                store.hasPhysicalAcceptor = this.storeInfos.hasPhysicalAcceptor;
                // store.hasChosenTerminalProvider = this.storeInfos.hasChosenTerminalProvider;
                store.isPhysicalAcceptorMastercard = this.storeInfos.isPhysicalAcceptorMastercard;
              }
            });

            this.currentStep = '3';
          } else {
            this.showToast(this.labels.lb_error, this.lastMIDErrMsg, 'error');
          }
          break;

        case '5':
          // Prepare arrays for chosen categories
          // this.merchantInfos.storesList.forEach((store) => {
          // this.chosenCategories.push(...this.categorieItems.filter((elem) => elem.isChecked));
          // debugLog(this.dbg, ">>> Chosen cats - nb chosenCategories" + this.chosenCategories.length);
          // });

          // Get Terms and conditions previously
          // if(!this.isOnBoarding) this.initTermsAndConditions();

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

          // if(!this.isOnBoarding){
          //   this.currentStep = !this.isReadOnly ? "7" : "8";
          // } else {
          this.currentStep = '3';
          // }

          break;

        case null:
          this.isStepMainOnboarding = false;
          this.currentStep = '8';
          let paramsJSON = {
            leadId: this.leadId,
            accountId: this.merchantInfos.accountId,
            country: this.merchantInfos.countryCode,
            contactEmail: this.merchantInfos.email,
            lang: this.lang,
            solution: this.solution,
            promoCode: this.merchantInfos.promoCode,
            scope: this.scope,
            versionId: this.termsAndConditions.tcVersion,
            uniqueKeyId: this.uniqueKeyId,
            isWebOffer: this.isWebOffer,
            version: this.version,
            contractId: this.merchantInfos.contractId
          };

          debugLog(this.dbg, '>>> Step7 - closeOpportunity() - paramsJSON ' + JSON.stringify(paramsJSON));

          doApexEvent({
            operationName: 'closeOpportunity',
            operationParams: JSON.stringify(paramsJSON)
          })
            .then((data) => {
              debugLog(this.dbg, '>>> closeOpportunity() - data ' + JSON.stringify(data));
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> closeOpportunity() - error ' + error);
            });
          break;

        case 'userStep':
          doApexEvent({
            operationName: 'createUsers',
            operationParams: this.merchantInfos.accountId + '|' + JSON.stringify(this.merchantInfos.usersList)
          })
            .then((data) => {
              debugLog(this.dbg, '>>> createUsers() - data ' + JSON.stringify(data));
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> createUsers() - error ' + error);
            });

          this.isStepMainOnboarding = true;
          this.isStepUsers = false;
          this.currentStep = null;
          break;
      }
      this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
      this.stepValidated = false;

      // saveToFile({
      //   merchantInfosJSON: JSON.stringify(this.merchantInfos)
      // })
      //   .then(() => {
      //     debugLog(this.dbg, '>>> saveToFile() - done ');
      //   })
      //   .catch((error) => {
      //     debugLog(this.dbg, '>>> saveToFile() - error ' + error);
      //   });
    }
  }

  handlePrev() {
    debugLog(this.dbg, 'handlePrev - this.currentStep = ' + this.currentStep);

    if (this.currentStep == '7') {
      if (!this.version) this.currentStep = '6'; // Auto enrollment v1
      else this.currentStep = '2'; // Auto enrollment v2
    }

    if (this.currentStep == '6') this.currentStep = '5';
    else if (this.currentStep == '5') this.currentStep = '3';
    else if (this.currentStep == '4') {
      if (this.isMIDChecked) {
        this.currentStep = '3';
      } else {
        this.showToast(this.labels.lb_error, this.lastMIDErrMsg, 'error');
      }
    } else if (this.currentStep == '3' || this.isStepUsers) {
      this.isStepMainOnboarding = true;
      this.currentStep = null;
    }
    this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
    debugLog(this.dbg, 'handlePrev - ***END***');
  }

  initCompanyInfos() {
    debugLog(this.dbg, '>>> initCompanyInfos1() - ***START***');
    this.companyInfos = [];
    this.companyInfos.push({
      [this.labels.lb_step1_enterprise_name]: this.merchantInfos.company
    });
    this.companyInfos.push({
      [this.labels.lb_contract_nb]: this.merchantInfos.contractNumber
    });
    this.companyInfos.push({
      [this.labels.lb_solution_name]: this.merchantInfos.solutionName
    });
    debugLog(this.dbg, '>>> initCompanyInfos1() - ***END*** this.companyInfos: ' + JSON.stringify(this.companyInfos));
  }

  checkCity(city, postalCode, context, cityFieldName) {
    checkCity({
      countryCode: this.country,
      city: city,
      postalCode: postalCode
    })
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

  validateStep() {
    // Get input and picklist fields
    let inputFields = [...this.template.querySelectorAll('c-er-portal-input')]; // this kind of assignment is done in order to be able to use .filter() function later

    this.stepValidated = this.checkDataQty(); // Check if items have already been created (it allows to go next step if one item saved even if user is starting to fill a new item)

    if (this.stepValidated) {
      let checkFormats, requiredFields;
      switch (this.currentStep) {
        case '3':
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
          mobileOrPhoneFields = inputFields.filter((elem) => elem.propertyName === 'storePhone');

          checkMobileOrPhone = true;
          if (mobileOrPhoneFields[0] && mobileOrPhoneFields[0].value) {
            debugLog(this.dbg, 'validateStep - mobileOrPhoneFields OK');
            mobileOrPhoneFields[0].hasError = false;
            mobileOrPhoneFields[0].errorMessage = '';
          }

          // check email, gsm or tel, regex tel
          checkFormats = this.validateFieldsFormat(inputFields);
          this.stepValidated = checkFormats && checkMobileOrPhone && requiredFields;
          debugLog(this.dbg, 'validateStep (1) - this.stepValidated = ' + this.stepValidated);
          // check that all mandatory fields on ALL stores are filled
          this.stepValidated = this.checkAllStoresData();
          debugLog(this.dbg, 'validateStep (2) - this.stepValidated = ' + this.stepValidated);

          break;
        // case "2":
        //   // check IBAN & promo inside component (not here)
        //   if((this.isWebOffer || this.existingAccount) && this.finCenterInfos && this.finCenterInfos.iban.includes("********")) this.isValidIBAN = true; // escape IBAN check if in web offer context & anonimized
        //   if(!this.isValidIBAN){ this.showToast(this.labels.lb_error, this.labels.lb_step2_msg_err_iban, "error"); }

        //   // check email, gsm or tel, regex tel
        //   checkFormats = this.validateFieldsFormat(inputFields);
        //   this.stepValidated = this.isValidIBAN && checkFormats;
        //   break;
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
        case 'storeEmail':
        case 'storeContactEmail':
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
        case 'storePhone':
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

  checkDataQty() {
    debugLog(this.dbg, 'checkDataQty *** START *** ');

    let isQtyOK = false;
    // Check if sufficient datas have been filled according to current step
    switch (this.currentStep) {
      case '2': // Fin centers, at least 1
        isQtyOK = this.merchantInfos.finCentersList.length > 0;
        if (!isQtyOK) this.showToast(this.labels.lb_error, this.labels.lb_step2_errmsg_nb_fincenter, 'error');
        break;
      case '3': // Stores, at least 1
        debugLog(this.dbg, 'checkDataQty - step3 this.chosenCategories: ' + JSON.stringify(this.chosenCategories));
        isQtyOK = this.merchantInfos.storesList.length > 0;
        if (!isQtyOK) {
          this.showToast(this.labels.lb_error, this.labels.lb_step3_errmsg_nb_store, 'error');
        } else {
          let nbAcceptorsStore = [];
          this.merchantInfos.storesList.forEach((store) =>
            nbAcceptorsStore.push(store.terminalsList?.length + store.hasOnlineStore + store.hasAgregator)
          );
          isQtyOK = !nbAcceptorsStore.includes(0);
          if (!isQtyOK) {
            this.showToast(this.labels.lb_error, this.labels.lb_step4_errmsg_nb_acceptor, 'error');
          } else {
            isQtyOK = this.checkSelectedCat(); // check if one cat selected at least for the solution
            if (isQtyOK) {
              let mainCats = 0;
              this.chosenCategories.forEach((cat) => {
                if (cat.isMain == 'true' || cat.isMain) mainCats++;
              });
              // isQtyOK = (mainCats == 1); //TODO to be fixed to accept only one main cat
              isQtyOK = mainCats > 0;
              debugLog(this.dbg, 'checkDataQty - step3 mainCats: ' + mainCats);
              debugLog(this.dbg, 'checkDataQty - step3 isQtyOK: ' + isQtyOK);
              if (!isQtyOK) this.showToast(this.labels.lb_error, this.labels.lb_step6_errmsg_nb_main_storecat, 'error');
            }
          }
        }
        break;
      case '4': // Acceptors, at least 1 per store
        isQtyOK =
          this.storeInfos.terminalsList?.length > 0 || this.storeInfos.hasOnlineStore || this.storeInfos.hasAgregator;
        if (!isQtyOK) this.showToast(this.labels.lb_error, this.labels.lb_step4_errmsg_nb_acceptor, 'error');
        break;
      case '5': // Store categories, at least 1
        isQtyOK = this.checkSelectedCat();
        break;
      case '6': // Main store categories, at least 1
        debugLog(this.dbg, 'checkDataQty - step6 this.chosenCategories: ' + JSON.stringify(this.chosenCategories));
        let mainCats = 0;
        if (this.chosenCategories)
          this.chosenCategories.forEach((cat) => {
            if (cat.isMain == 'true' || cat.isMain === true) mainCats++;
          });
        // isQtyOK = (mainCats == 1);
        isQtyOK = mainCats > 0; // TODO to be fixed with pb of many main cats
        debugLog(this.dbg, 'checkDataQty - step6 mainCats: ' + mainCats);
        debugLog(this.dbg, 'checkDataQty - step6 isQtyOK: ' + isQtyOK);
        if (!isQtyOK) this.showToast(this.labels.lb_error, this.labels.lb_step6_errmsg_nb_main_storecat, 'error');
        break;
      default:
        isQtyOK = true;
        break;
    }
    debugLog(this.dbg, 'checkDataQty - isQtyOK = ' + isQtyOK + ' for step ' + this.currentStep);

    return isQtyOK;
  }

  checkSelectedCat() {
    let selectedCats = 0;
    let result = false;
    debugLog(this.dbg, 'checkDataQty - checkSelectedCat this.previousCats: ' + JSON.stringify(this.previousCats));
    this.chosenCategories.forEach((cat) => {
      debugLog(this.dbg, 'checkDataQty - checkSelectedCat cat.id / cat.isChecked: ' + cat.id + ' / ' + cat.isChecked);
      debugLog(
        this.dbg,
        'checkDataQty - checkSelectedCat cat.isChecked test: ' +
          ((cat.isChecked == 'true' || cat.isChecked === true) && !this.previousCats.includes(cat.id))
      );
      if ((cat.isChecked == 'true' || cat.isChecked === true) && !this.previousCats.includes(cat.id)) selectedCats++;
    });
    debugLog(this.dbg, 'checkDataQty - checkSelectedCat selectedCats: ' + selectedCats);
    result = selectedCats > 0;
    debugLog(
      this.dbg,
      'checkDataQty - checkSelectedCat this.chosenCategories: ' + JSON.stringify(this.chosenCategories)
    );
    if (!result) this.showToast(this.labels.lb_error, this.labels.lb_step5_errmsg_nb_storecat, 'error');
    return result;
  }

  checkAllStoresData() {
    let result = true;
    this.merchantInfos.storesList.forEach((store) => {
      this.storeMandatoryFields.forEach((field) => {
        if (!store[field]) {
          let errMsg = buildTemplate(this.labels.lb_err_msg_complete_store, [store.name]);
          this.showToast(this.labels.lb_error, errMsg, 'error');
          result = false;
        }
      });
    });
    return result;
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

  handleStoreInfos(event) {
    //TODO voir si factorisable?
    debugLog(this.dbg, 'handleStoreInfos ***Start*** ');
    debugLog(
      this.dbg,
      'handleStoreInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value + ' or ' + event.detail
    );
    this.storeInfos[event.detail.field] = event.detail.value;
    debugLog(this.dbg, 'handleStoreInfos picklist: ' + JSON.stringify(this.picklistGroup.finCenterId));

    // set picklist to the right option
    if (event.detail.picklist) {
      // debugLog(this.dbg, "handleStoreInfos is picklist ");
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
      debugLog(
        this.dbg,
        'handleStoreInfos new picklist value: ' + JSON.stringify(this.picklistGroup[event.detail.field])
      );
      if (event.detail.field === 'finCenterId')
        this.storeInfos.finCenterName = this.picklistGroup.finCenterId.filter(
          (elem) => elem.key == event.detail.value
        )[0].value;
    }

    // Check city according to postalCode
    if (
      (event.detail.field === 'postalCode' || event.detail.field === 'city') &&
      this.storeInfos.postalCode &&
      this.storeInfos.city
    ) {
      this.checkCity(this.storeInfos.city, this.storeInfos.postalCode, this.storeInfos, 'city');
    }
    this.savStoreBtnDisabled = false;

    //Manage checkboxes
    if (event.detail === true || event.detail === false) {
      let cbxList = this.template.querySelectorAll('c-er-portal-cbx[data-group="store"]');

      cbxList.forEach((cbx) => {
        this.storeInfos[cbx.propertyName] = cbx.isChecked;
      });
      // if(!this.storeInfos.isWebShop) this.storeInfos.webShopUrl = "";
      // if(!this.storeInfos.mastercardAccepted) this.storeInfos.mid = "";
    }

    // remove storeContactId if one of the contact fields modified
    if (event.detail.field.startsWith('storeContact')) this.storeInfos.storeContactId = '';

    if (['mid', 'subMid'].includes(event.detail.field)) {
      this.checkDuplicateMID(this.storeInfos.mid, this.storeInfos.subMid, this.storeInfos.storeId);
    }
    if (['mid2', 'subMid2'].includes(event.detail.field)) {
      this.checkDuplicateMID(this.storeInfos.mid2, this.storeInfos.subMid2, this.storeInfos.storeId);
    }

    debugLog(this.dbg, 'handleStoreInfos ***END*** ');
  }

  // Edit stores
  handleEditStore(event) {
    debugLog(this.dbg, 'handleEditStore - ***Start*** ');
    this.isReadOnlyEditable = false;
    this.showStoreDetails = true;
    let fieldList = this.template.querySelectorAll('[data-group="store"]');
    debugLog(this.dbg, 'handleEditStore - fieldList length = ' + fieldList.length);

    debugLog(
      this.dbg,
      'handleEditStore - Row to be displayed: ' + JSON.stringify(this.merchantInfos.storesList[event.detail.value])
    );
    initFields(fieldList, this.merchantInfos.storesList[event.detail.value], this.isReadOnly); // Init input fields
    this.storeInfos = JSON.parse(JSON.stringify(this.merchantInfos.storesList[event.detail.value])); // Init storeinfos object too (tbc? as it should have been done by initFields)
    this.storeInfos.storeIndex = this.merchantInfos.storesList.findIndex(
      (store) => store.storeId === this.storeInfos.storeId
    ); //Set store index
    debugLog(this.dbg, 'handleEditStore - this.storeInfos = ' + JSON.stringify(this.storeInfos));

    // Set picklists displayed values
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist'));

    debugLog(this.dbg, 'handleEditStore -- this.storeInfos.isFranchisee ' + this.storeInfos.isFranchisee);
    this.storeInfos.showFranchiseeField = this.storeInfos.isFranchisee === 'Yes';
    debugLog(this.dbg, 'handleEditStore -- this.storeInfos.showFranchiseeField ' + this.storeInfos.showFranchiseeField);

    this.template.querySelectorAll('c-er-portal-cbx[data-group="store"]').forEach((cbx) => {
      cbx.isChecked = this.storeInfos[cbx.propertyName];
    });
    this.storeInfos.terminalInfos = {};
    this.storeInfos.terminalInfos.rowIndex = 0;

    debugLog(this.dbg, 'handleEditStore *** END *** ');
  }

  initStoreFirstRecord(event) {
    debugLog(this.dbg, 'handleEditStore2 *** initStoreFirstRecord Start *** ');
    // this.handleEditStore(event);
    // Set picklists displayed values
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist'));
    if (this.isWebOffer) {
      this.isReadOnlyEditable = true;
      this.template.querySelectorAll('[data-group="store"]').forEach((field) => {
        field.disabled = true;
      });
    }
    debugLog(
      this.dbg,
      'handleEditStore2 *** initStoreFirstRecord END *** this.isReadOnlyEditable = ' + this.isReadOnlyEditable
    );
  }

  handleDeleteStore(event) {
    debugLog(this.dbg, 'handleDeleteStore -- Start ');

    this.merchantInfos.storesList.splice(event.detail.value, 1);
    this.template.querySelector('[data-id="copyCompanyAddress"]').isChecked = false;
    this.setRowIndex(this.storeInfos, this.merchantInfos.storesList, 'storeId');
    this.newStore();
  }

  /*************************************************************/
  /******************* Merchant User methods *******************/
  /*************************************************************/
  newMerchantUser() {
    debugLog(this.dbg, 'newMerchantUser2 - START');
    this.merchantUserInfos = {};
    this.merchantUserInfos.userSalutation =
      this.merchantUserInfos.userFirstName =
      this.merchantUserInfos.userLastName =
      this.merchantUserInfos.userName =
      this.merchantUserInfos.userEmail =
      this.merchantUserInfos.userLanguage =
        '';
    resetPicklist([this.picklistGroup.userSalutation, this.picklistGroup.userLang]);
    debugLog(this.dbg, 'newMerchantUser - this.merchantUserInfos: ' + JSON.stringify(this.merchantUserInfos));
    debugLog(this.dbg, 'newMerchantUser - END');
  }

  handleMerchantUserInfos(event) {
    debugLog(
      this.dbg,
      'handleMerchantUserInfos ***Start***  - name: ' +
        event.detail.field +
        ' - val: ' +
        event.detail.value +
        ' or ' +
        event.detail
    );
    this.merchantUserInfos[event.detail.field] = event.detail.value;
    // set picklist to the right option
    if (event.detail.picklist)
      this.picklistGroup[event.detail.field] = initPicklistValue(
        this.picklistGroup[event.detail.field],
        event.detail.value
      );
    debugLog(
      this.dbg,
      'handleMerchantUserInfos ***END***  - this.merchantUserInfos: ' + JSON.stringify(this.merchantUserInfos)
    );
  }

  handleEditMerchantUser(event) {
    debugLog(this.dbg, 'handleEditMerchantUser *** START *** ');
    // this.displayUser(event.target.id, event.detail.value);
    this.merchantUserInfos = JSON.parse(JSON.stringify(this.merchantInfos.usersList[event.detail.value])); // Init storeinfos object too (tbc? as it should have been done by initFields)

    // Set picklists displayed values
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist'));

    debugLog(
      this.dbg,
      'handleEditMerchantUser *** END *** this.merchantUserInfos = ' + JSON.stringify(this.merchantUserInfos)
    );
  }

  handleDeleteMerchantUser(event) {
    debugLog(this.dbg, 'handleDeleteMerchantUser -- Start ');
    this.merchantInfos.usersList.splice(event.detail.value, 1);
    this.setRowIndex(this.merchantUserInfos, this.merchantInfos.usersList, 'userId');
    this.newMerchantUser();
    debugLog(this.dbg, 'handleDeleteMerchantUser -- END ');
  }

  saveMerchantUser() {
    debugLog(
      this.dbg,
      'saveMerchantUser *** START *** this.merchantUserInfos: ' + JSON.stringify(this.merchantUserInfos)
    );
    debugLog(this.dbg, 'saveMerchantUser this.merchantUser.contractId: ' + this.merchantInfos.contractId);
    if (this.merchantUserInfos.userSFId) this.merchantUserInfos.noDelete = true; // to hide delete button in data table

    this.merchantUserInfos.userName = this.merchantUserInfos.userFirstName + ' ' + this.merchantUserInfos.userLastName;

    let userReorderedCols = {
      userId: this.merchantUserInfos.userId,
      userSFId: this.merchantUserInfos.userSFId,
      userName: this.merchantUserInfos.userName,
      userEmail: this.merchantUserInfos.userEmail,
      contractId: this.merchantInfos.contractId,
      userSalutation: this.merchantUserInfos.userSalutation,
      userFirstName: this.merchantUserInfos.userFirstName,
      userLastName: this.merchantUserInfos.userLastName,
      userLanguage: this.merchantUserInfos.userLanguage
    };

    this.merchantUserInfos = userReorderedCols;
    debugLog(this.dbg, 'saveMerchantUser this.merchantUserInfos = ' + JSON.stringify(this.merchantUserInfos));

    let fieldList = this.template.querySelectorAll('[data-group="merchantUser"]');

    let checkFields = checkRequiredFields(fieldList, this.labels.lb_err_msg_required_field);
    let checkFormats = this.validateFieldsFormat(fieldList);

    if (checkFields && checkFormats) {
      if (!this.merchantUserInfos.userId) {
        // case new user
        this.setRowIndex(this.merchantUserInfos, this.merchantInfos.usersList, 'userId');
        this.merchantInfos.usersList.push(JSON.parse(JSON.stringify(this.merchantUserInfos)));
      } else {
        const userIndex = this.merchantInfos.usersList.findIndex(
          (user) => user.userId === this.merchantUserInfos.userId
        );
        this.merchantInfos.usersList.splice(userIndex, 1, JSON.parse(JSON.stringify(this.merchantUserInfos)));
      }
    }
    this.newMerchantUser();
    debugLog(
      this.dbg,
      'saveMerchantUser this.merchantInfos.usersList: ' + JSON.stringify(this.merchantInfos.usersList)
    );
    debugLog(this.dbg, 'saveMerchantUser *** END *** Nb of users: ' + this.merchantInfos.usersList.length);
  }

  /*************************************************************/
  /******************* Merchant User methods ** End ** *********/
  /*************************************************************/

  newStore() {
    debugLog(this.dbg, 'newStore - START');
    this.showStoreDetails = true;
    this.storeInfos = {};
    debugLog(this.dbg, 'newStore - 1');

    if (this.picklistGroup.finCenterId) resetPicklist([this.picklistGroup.finCenterId]);
    debugLog(this.dbg, 'newStore - 1a');
    resetPicklist([
      this.picklistGroup.sector,
      this.picklistGroup.isFranchisee,
      this.picklistGroup.storeCountry,
      this.picklistGroup.storeContactSalutation,
      this.picklistGroup.storeContactLang
    ]);

    debugLog(this.dbg, 'newStore - 2');

    this.template.querySelector('[data-id="sector"]').disabled = true;
    this.storeInfos.finCenterId =
      this.storeInfos.isFranchisee =
      this.storeInfos.sector =
      this.storeInfos.country =
      this.storeInfos.storeContactSalutation =
      this.storeInfos.storeContactLanguage =
        '';
    // this.template.querySelector('[data-id="copyCompanyAddress"]').isChecked = false;

    // Init store contact if only one fin center (v2)
    if (this.merchantInfos.finCentersList.length == 1) {
      this.storeInfos.storeContactSalutation = this.merchantInfos.finCentersList[0].refundSalutation;
      this.storeInfos.storeContactFirstName = this.merchantInfos.finCentersList[0].refundFirstName;
      this.storeInfos.storeContactLastName = this.merchantInfos.finCentersList[0].refundLastName;
      this.storeInfos.storeContactEmail = this.merchantInfos.finCentersList[0].refundEmail;
      this.storeInfos.storeContactLanguage = this.merchantInfos.finCentersList[0].refundLang;
    }

    this.template.querySelectorAll('c-er-portal-cbx[data-group="store"]').forEach((cb) => (cb.isChecked = false));
    this.template.querySelector('[data-id="storeBlock"]').scrollIntoView();

    debugLog(this.dbg, 'newStore - END');
  }

  newStoreOnboarding() {
    debugLog(this.dbg, 'newStoreOnboarding - START');
    this.isStepMainOnboarding = false;
    this.retrieveAcceptorModels();
    // debugLog(this.dbg, "newStoreOnboarding - this.currentStore: " + JSON.stringify(this.currentStore));

    // if(this.currentStore) this.currentStore.terminalInfos = {};
    // this.currentStore.picklistGroup = {};
    debugLog(this.dbg, 'newStoreOnboarding - 1');
    if (!this.initCategoriesDone) this.initCategories();
    this.initCategoriesDone = true;
    debugLog(this.dbg, 'newStoreOnboarding - 2 - this.merchantInfos: ' + JSON.stringify(this.merchantInfos));
    this.currentStep = '3';
    debugLog(this.dbg, 'newStoreOnboarding - END');
  }

  newMerchantUserOnboarding() {
    this.isStepMainOnboarding = false;
    this.isStepUsers = true;
    this.currentStep = 'userStep';
  }

  handleCopyCompanyAddress(event) {
    debugLog(this.dbg, 'handleCopyCompanyAddress *** START *** ');
    let store = this.storeInfos; // Set alias
    if (event.detail) {
      store.address = this.merchantInfos.address;
      store.postalCode = this.merchantInfos.postalCode;
      store.city = this.merchantInfos.city;
      store.country = this.merchantInfos.country;

      // Copy fin center contact infos (v2)
      let storeFc = this.merchantInfos.finCentersList.filter(
        (fc) => fc.finCenterId == (store.finCenterId ? store.finCenterId : 1)
      );
      debugLog(this.dbg, 'handleCopyCompanyAddress storeFc: ' + JSON.stringify(storeFc));
      store.storeContactSalutation = storeFc[0].refundSalutation;
      store.storeContactFirstName = storeFc[0].refundFirstName;
      store.storeContactLastName = storeFc[0].refundLastName;
      store.storeContactEmail = storeFc[0].refundEmail;
      store.storeContactLanguage = storeFc[0].refundLang;
    } else {
      store.address =
        store.postalCode =
        store.city =
        store.country =
        store.storeContactSalutation =
        store.storeContactFirstName =
        store.storeContactLastName =
        store.storeContactEmail =
        store.storeContactLanguage =
          '';
    }

    this.picklistGroup.storeCountry = JSON.parse(JSON.stringify(this.picklistGroup.country));
    this.picklistGroup.storeContactSalutation = JSON.parse(JSON.stringify(this.picklistGroup.storeContactSalutation));
    this.picklistGroup.storeContactLang = JSON.parse(JSON.stringify(this.picklistGroup.storeContactLang));

    this.savStoreBtnDisabled = false;
    debugLog(this.dbg, 'handleCopyCompanyAddress *** END *** ');
  }

  handleIsFranchisee(event) {
    debugLog(this.dbg, 'handleIsFranchisee start ');
    this.handleStoreInfos(event);
    this.storeInfos.showFranchiseeField = this.storeInfos.isFranchisee === 'Yes';

    // enable/disable Sector picklist according to isFranchisee
    this.template.querySelector('[data-id="sector"]').disabled = !this.storeInfos.isFranchisee;
    debugLog(this.dbg, 'handleIsFranchisee (!this.storeInfos.isFranchisee) ==> ' + !this.storeInfos.isFranchisee);

    // Disable "Local Store TRE" entry if franchisee picklist equals Yes
    this.picklistGroup.sector.forEach((elem) => {
      if (elem.key === 'Local Store TRE') {
        elem.hidden = this.storeInfos.isFranchisee === 'Yes';
        if ((elem.selected === true && elem.hidden) || !this.storeInfos.isFranchisee) {
          this.storeInfos.sector = '';
          elem.selected = false;
          this.picklistGroup.sector[0].selected = true;
        }
      }
    });
    debugLog(this.dbg, 'handleIsFranchisee END ');
  }

  saveStore() {
    let store = this.storeInfos; //Set Alias
    store.fullAddress = store.address + ', ' + store.postalCode + ' ' + store.city;
    debugLog(this.dbg, 'saveStore this.storeInfos: ' + JSON.stringify(this.storeInfos));
    store.finCenterName = store.finCenterName ? store.finCenterName : this.merchantInfos.finCentersList[0].name;
    debugLog(this.dbg, 'saveStore. store.finCenterName: ' + store.finCenterName);

    // Reorder Store columns to adjust datatable display
    let storeReorderedCols = {
      name: store.name,
      fullAddress: store.fullAddress,
      finCenterName: store.finCenterName,
      website: store.website,
      address: store.address,
      postalCode: store.postalCode,
      city: store.city,
      countryCode: this.country,
      country: store.country,
      facebook: store.facebook,
      isFranchisee: store.isFranchisee,
      sector: store.sector,
      franchiseeBrand: store.franchiseeBrand,
      showFranchiseeField: store.showFranchiseeField,
      finCenterId: store.finCenterId ? store.finCenterId : 1,
      storeId: store.storeId,
      terminalsList: store.terminalsList,
      terminalInfos: store.terminalInfos,
      picklistGroup: store.picklistGroup,
      rowIndex: store.rowIndex,
      storeSFId: store.storeSFId,
      merchantAccSFId: this.merchantInfos.accountId,
      storeStatus: store.storeStatus,
      storeStartDate: store.storeStartDate,
      storeContactId: store.storeContactId,
      mid: store.mid,
      mid2: store.mid2,
      subMid: store.subMid,
      subMid2: store.subMid2,
      midCtap: store.midCtap,
      hasOnlineStore: store.hasOnlineStore,
      isOnlineStoreMastercard: store.isOnlineStoreMastercard,
      hasAgregator: store.hasAgregator,
      hasPhysicalAcceptor: store.hasPhysicalAcceptor,
      isPhysicalAcceptorMastercard: store.isPhysicalAcceptorMastercard,
      storeContactSalutation: store.storeContactSalutation,
      storeContactFirstName: store.storeContactFirstName,
      storeContactLastName: store.storeContactLastName,
      storeContactEmail: store.storeContactEmail,
      storeContactLanguage: store.storeContactLanguage,
      storePhone: store.storePhone,
      storeEmail: store.storeEmail
    };

    store = storeReorderedCols;
    if (store.storeSFId) store.noDelete = true; // to hide delete button in data table

    let fieldList = this.template.querySelectorAll('[data-group="store"]');
    let checkFields = checkRequiredFields(fieldList, this.labels.lb_err_msg_required_field);
    let checkFormats = this.validateFieldsFormat(fieldList);

    debugLog(this.dbg, 'saveStore. store.picklistGroup2: ' + JSON.stringify(store.picklistGroup));

    debugLog(this.dbg, 'saveStore -- req field checked:  ' + checkFields);
    if (checkFields && checkFormats) {
      if (!store.picklistGroup) {
        store.picklistGroup = {};
        store.picklistGroup.terminalProvider = JSON.parse(JSON.stringify(this.picklistGroup.terminalProvider));
        store.picklistGroup.terminalModel = JSON.parse(JSON.stringify(this.picklistGroup.terminalModel));
        store.picklistGroup.isLinkedToCashReg = JSON.parse(JSON.stringify(this.picklistGroup.isLinkedToCashReg));
      }

      if (store.storeId) {
        // case existing store, then update
        debugLog(this.dbg, 'saveStore Update');

        debugLog(
          this.dbg,
          'saveStore Update this.merchantInfos.storesList0: ' + JSON.stringify(this.merchantInfos.storesList)
        );
        debugLog(this.dbg, 'saveStore Update store.storeId: ' + store.storeId);
        const storeIndex = this.merchantInfos.storesList.findIndex((store2) => store2.storeId === store.storeId);
        debugLog(this.dbg, 'saveStore Update this.storeInfos: ' + JSON.stringify(store));
        debugLog(this.dbg, 'saveStore Update storeIndex: ' + storeIndex);

        this.merchantInfos.storesList.splice(storeIndex, 1, store);
        debugLog(
          this.dbg,
          'saveStore Update this.merchantInfos.storesList1: ' + JSON.stringify(this.merchantInfos.storesList)
        );
      } else {
        // case new store, then insert
        debugLog(this.dbg, 'saveStore Insert');

        //Set storeID in order to link terminals to the right store
        store.storeId = this.getStoreId();

        // Init properties for terminals(in order to prepare the display of data table and terminal fields for each store in terminal page)
        store.terminalsList = [];
        store.terminalInfos = {};

        debugLog(this.dbg, 'saveStore Insert store: ' + JSON.stringify(store));

        if (this.merchantInfos.storesList.length && this.merchantInfos.storesList[0].name == '') {
          this.merchantInfos.storesList.splice(0, 1, JSON.parse(JSON.stringify(store))); // Case onboarding when creating 1st store
        } else {
          this.merchantInfos.storesList.push(JSON.parse(JSON.stringify(store)));
        }
        this.setRowIndex(store, this.merchantInfos.storesList, 'storeId');
        this.storeInfos.storeIndex = store.rowIndex;

        debugLog(this.dbg, 'saveStore Insert done');
      }

      this.showToast(this.labels.lb_success, this.labels.lb_msg_update_success, 'success');
      this.savStoreBtnDisabled = true;
      this.template.querySelector('c-er-portal-data-table').scrollIntoView();
      this.showStoreDetails = false;
    }
    this.storeInfos = store;
    debugLog(this.dbg, 'saveStore  -- ***END*** this.storeInfos: ' + JSON.stringify(this.storeInfos));
  }

  getStoreId() {
    debugLog(
      this.dbg,
      'getStoreId  -- ***START*** this.merchantInfos.storesList: ' + JSON.stringify(this.merchantInfos.storesList)
    );
    let storeIdList = this.merchantInfos.storesList.map((store) => store.storeId);
    debugLog(this.dbg, 'getStoreId  -- storeIdList: ' + JSON.stringify(storeIdList));
    debugLog(this.dbg, 'getStoreId  -- result: ' + (storeIdList.length === 0 ? 1 : Math.max(...storeIdList) + 1));
    return storeIdList.length === 0 || storeIdList[0] == null ? 1 : Math.max(...storeIdList) + 1;
  }

  handleHasOnlineStore(event) {
    this.storeInfos.hasOnlineStore = this.storeInfos.hasOnlineStore = event.detail == 'true';
    debugLog(this.dbg, 'handleHasOnlineStore  -- this.storeInfos: ' + JSON.stringify(this.storeInfos));
  }

  handleIsOnlineStoreMastercard(event) {
    this.storeInfos.isOnlineStoreMastercard = event.detail == 'true';
    if (!this.storeInfos.isOnlineStoreMastercard) {
      this.showToast(null, this.labels.lb_web_shop_no_mastercard, 'info');
      this.storeInfos.mid = '';
      this.storeInfos.subMid = '';
    }
  }

  handleHasAgregator(event) {
    this.storeInfos.hasAgregator = this.storeInfos.hasAgregator = event.detail == 'true';
  }

  handleHasPhysicalAcceptor(event) {
    this.storeInfos.hasPhysicalAcceptor = event.detail == 'true';
    this.hideCreateTerminalBlock = false;
    // this.newTerminal();
  }

  handleIsPhysicalAcceptorMastercard(event) {
    debugLog(this.dbg, 'handleIsPhysicalAcceptorMastercard *** START ***');
    this.storeInfos.isPhysicalAcceptorMastercard = event.detail == 'true';

    // if (this.storeInfos.hasChosenTerminalProvider && !this.storeInfos.isPhysicalAcceptorMastercard) {
    if (!this.storeInfos.isPhysicalAcceptorMastercard) {
      this.storeInfos.mid2 = '';
      this.storeInfos.subMid2 = '';
      // if (this.mastercardOnlyProviders.includes(this.storeInfos.terminalInfos.terminalProvider)) {
      //   this.storeInfos.showCreateAcceptor = false;
      //   let errMsg = buildTemplate(this.labels.lb_physical_terminal_not_accepted, [this.merchantInfos.solutionName]);
      //   this.showToast(this.labels.lb_error, errMsg, 'error');
      // } else {
      //   this.storeInfos.showCreateAcceptor = true;
      // }
      // } else if (this.storeInfos.isPhysicalAcceptorMastercard) {
      //   this.storeInfos.showCreateAcceptor = true;
    }
  }

  // Edit Terminal infos
  handleEditTerminal(event) {
    debugLog(this.dbg, 'handleEditTerminal *** START *** ');
    // this.showTerminalBlock = true;
    this.storeInfos.showCreateAcceptor = true;
    this.hideCreateTerminalBlock = false;
    // this.storeInfos.hasChosenTerminalProvider = true;
    // this.storeInfos.isPhysicalAcceptorMastercard = true;

    let curStore = this.storeInfos;
    this.displayTerminal(curStore, event.target.id, event.detail.value);
    debugLog(this.dbg, 'handleEditTerminal *** END *** ');
  }

  showTerminalFields(event) {
    debugLog(this.dbg, 'showTerminalFields *** START *** ');
    // this.showTerminalBlock = true;
    this.storeInfos.showCreateAcceptor = true;
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist[id="' + event.target.id + '"]'));

    debugLog(this.dbg, 'showTerminalFields *** END *** ');
  }

  // Display Terminal infos
  displayTerminal(curStore, targetId, terminalIndex) {
    // let fieldList = this.template.querySelectorAll('c-er-portal-picklist[id="' + targetId + '"], c-er-portal-input[id="' + targetId + '"]');
    let fieldList = this.template.querySelectorAll('[data-group="terminal"]');

    debugLog(this.dbg, 'displayTerminal - targetId: ' + targetId);
    debugLog(this.dbg, 'displayTerminal - terminalIndex: ' + terminalIndex);
    debugLog(
      this.dbg,
      'displayTerminal - Row to be displayed: ' + JSON.stringify(curStore.terminalsList[terminalIndex])
    );
    initFields(fieldList, curStore.terminalsList[terminalIndex], curStore.terminalsList[terminalIndex].isReadOnly);
    curStore.terminalInfos = JSON.parse(JSON.stringify(curStore.terminalsList[terminalIndex])); // Init terminalInfos too (tbc? as it should have been done by initFields)

    // Set picklists displayed values
    initPicklistDisplay(this.template.querySelectorAll('c-er-portal-picklist[id="' + targetId + '"]'));

    debugLog(this.dbg, 'displayTerminal *** END *** ');
  }

  handleDeleteTerminal(event) {
    debugLog(this.dbg, '>>> handleDeleteTerminal() -- Start');
    let curStore = this.storeInfos; // create "alias" to have code lighter and easier to read

    // const terminalId = curStore.terminalsList[event.detail.value].terminalId;
    debugLog(this.dbg, '>>> handleDeleteTerminal() -- curStore.terminalsList size: ' + curStore.terminalsList.length);
    // curStore.terminalsList = curStore.terminalsList.filter(terminal => terminal.terminalId !== terminalId);
    // debugLog(this.dbg, '>>> handleDeleteTerminal() -- curStore.terminalsList size2: ' + curStore.terminalsList.length);
    curStore.terminalsList.splice(event.detail.value, 1);
    debugLog(this.dbg, '>>> handleDeleteTerminal() -- curStore.terminalsList size3: ' + curStore.terminalsList.length);

    this.newTerminal(); // In order to empty all fields
    debugLog(this.dbg, '>>> handleDeleteTerminal() -- this.newTerminal() ok');
    if (!this.storeInfos.terminalsList || this.storeInfos?.terminalsList.length === 0) {
      this.storeInfos.terminalsList = [];
      this.storeInfos.terminalsList.push({
        terminalId: 1,
        terminalProvider: ' ',
        terminalModelDisplayValue: ' ',
        tid: ' ',
        cashRegisterProvider: ' ',
        isLinkedToCashRegDisplayValue: ' '
      });
      this.storeInfos.terminalInfos.terminalId = 1; // In order to match first terminal with the first empty record of the data table
    }

    if (this.storeInfos?.terminalsList.length > 0)
      this.setRowIndex(curStore.terminalInfos, curStore.terminalsList, 'terminalId');
    // Sync with merchantInfos
    this.merchantInfos.storesList.forEach((store) => {
      if (store.storeId == this.storeInfos.storeId)
        store.terminalsList = JSON.parse(JSON.stringify(curStore.terminalsList));
    });

    debugLog(
      this.dbg,
      '>>> handleDeleteTerminal() -- curStore.terminalInfos: ' + JSON.stringify(curStore.terminalInfos)
    );
    debugLog(this.dbg, 'handleDeleteTerminal - END');
  }

  retrieveAcceptorModels() {
    getAcceptorModels()
      .then((data) => {
        debugLog(this.dbg, '>>> getAcceptorModels() - data ' + JSON.stringify(data));
        this.terminalProvidersAndModels = data;
        debugLog(
          this.dbg,
          '>>> getAcceptorModels() - this.picklistGroup.terminalProvider ' +
            JSON.stringify(this.picklistGroup.terminalProvider)
        );
        this.picklistGroup = JSON.parse(JSON.stringify(this.picklistGroupInherit));
        this.picklistGroup.terminalProvider.push({ key: '...', value: '', hidden: true });
        debugLog(
          this.dbg,
          '>>> getAcceptorModels() - this.picklistGroup.terminalProvider2 ' +
            JSON.stringify(this.picklistGroup.terminalProvider)
        );
        const providers_not_compatible = this.labels.not_compatible_providers.split('|');
        debugLog(
          this.dbg,
          '>>> getAcceptorModels() - providers_not_compatible ' + JSON.stringify(providers_not_compatible)
        );
        Object.keys(data).forEach((provider) => {
          if (!providers_not_compatible.includes(provider)) {
            this.picklistGroup.terminalProvider.push({ key: provider, value: provider });
          }
        });
        debugLog(this.dbg, '>>> getAcceptorModels() - this.storeInfos ' + JSON.stringify(this.storeInfos));
        this.merchantInfos.storesList.forEach((store) => {
          // Init stores related picklists
          store.terminalInfos = {};
          store.picklistGroup = {};
          store.picklistGroup.terminalProvider = JSON.parse(JSON.stringify(this.picklistGroup.terminalProvider));
          store.picklistGroup.terminalModel = JSON.parse(JSON.stringify(this.picklistGroup.terminalModel));
          store.picklistGroup.isLinkedToCashReg = JSON.parse(JSON.stringify(this.picklistGroup.isLinkedToCashReg));
          debugLog(this.dbg, '>>> getAcceptorModels() - store.picklistGroup ' + JSON.stringify(store.picklistGroup));
        });
        // Set picklist on current storeInfos too
        this.storeInfos.picklistGroup = {};
        this.storeInfos.picklistGroup.terminalProvider = JSON.parse(
          JSON.stringify(this.picklistGroup.terminalProvider)
        );
        this.storeInfos.picklistGroup.terminalModel = JSON.parse(JSON.stringify(this.picklistGroup.terminalModel));
        this.storeInfos.picklistGroup.isLinkedToCashReg = JSON.parse(
          JSON.stringify(this.picklistGroup.isLinkedToCashReg)
        );
        debugLog(this.dbg, '>>> getAcceptorModels() - this.storeInfos2 ' + JSON.stringify(this.storeInfos));
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getAcceptorModels() - error ' + error);
      });
  }

  newTerminal() {
    debugLog(this.dbg, '>>> newTerminal() -- Start ');
    debugLog(this.dbg, '>>> newTerminal() -- this.storeInfos ' + JSON.stringify(this.storeInfos));
    debugLog(
      this.dbg,
      '>>> newTerminal() -- this.storeInfos.picklistGroup ' + JSON.stringify(this.storeInfos.picklistGroup)
    );
    this.hideCreateTerminalBlock = false;
    // this.storeInfos.hasChosenTerminalProvider = false;
    // this.storeInfos.isPhysicalAcceptorMastercard = false;
    this.storeInfos.showCreateAcceptor = false;
    if (!this.storeInfos.picklistGroup) this.storeInfos.picklistGroup = {};
    debugLog(
      this.dbg,
      '>>> newTerminal() -- this.storeInfos.picklistGroup2 ' + JSON.stringify(this.storeInfos.picklistGroup)
    );
    // this.showTerminalBlock = true;
    this.storeInfos.showCreateAcceptor = true;
    let curStore = this.storeInfos;

    if (this.isReadOnly) {
      let fieldList = this.template.querySelectorAll('[data-group="terminal"]');
      fieldList.forEach((field) => (field.disabled = false));
    }
    debugLog(this.dbg, '>>> newTerminal() -- fields enabled ');

    curStore.terminalInfos = {};
    curStore.terminalInfos.isNew = true;
    // curStore.terminalInfos.terminalId = null;
    curStore.terminalInfos.terminalId =
      curStore.terminalsList.length == 1 && curStore.terminalsList[0].terminalProvider == ' ' ? 1 : null;
    resetPicklist([
      curStore.picklistGroup.terminalProvider,
      curStore.picklistGroup.terminalModel,
      curStore.picklistGroup.isLinkedToCashReg
    ]);

    debugLog(this.dbg, '>>> newTerminal() -- pklist reset done ');

    this.template.querySelector('[data-id="terminalBlock"]')?.scrollIntoView();

    debugLog(this.dbg, '>>> newTerminal() -- End -- curStore.terminalInfos: ' + JSON.stringify(curStore.terminalInfos));
  }

  handleTerminalInfos(event) {
    //TODO voir si factorisable?
    debugLog(
      this.dbg,
      '>>> handleTerminalInfos() -- START -- field: ' + event.detail.field + ' value: ' + event.detail.value
    );
    debugLog(this.dbg, '>>> handleTerminalInfos() -- START -- storeInfos.storeIndex: ' + this.storeInfos.storeIndex);
    let curStore = this.storeInfos; // create "alias" to have code lighter and easier to read
    debugLog(this.dbg, '>>> handleTerminalInfos() curStore: ' + JSON.stringify(curStore));
    let terminalId = curStore.terminalInfos.terminalId
      ? curStore.terminalInfos.terminalId
      : this.getTerminalId(curStore);
    debugLog(this.dbg, '>>> handleTerminalInfos() terminalId: ' + terminalId);

    //case checkbox
    if (event.detail.field == undefined && (event.detail === true || event.detail === false)) {
      let cbxList = this.template.querySelectorAll('c-er-portal-cbx[data-group="terminal"]');
      debugLog(this.dbg, '>>> handleTerminalInfos() **CBX** cbxList: ' + JSON.stringify(cbxList));
      cbxList.forEach((cbx) => {
        curStore.terminalInfos[cbx.propertyName] = cbx.isChecked;
      });
      debugLog(
        this.dbg,
        '>>> handleTerminalInfos() **CBX** curStore.terminalInfos: ' + JSON.stringify(curStore.terminalInfos)
      );
    }

    curStore.terminalInfos[event.detail.field] = event.detail.value;
    debugLog(this.dbg, '>>> handleTerminalInfos() -- terminalInfos: ' + JSON.stringify(curStore.terminalInfos));

    // set picklist to the right option
    if (event.detail.picklist && curStore.picklistGroup[event.detail.field]) {
      curStore.picklistGroup[event.detail.field] = initPicklistValue(
        curStore.picklistGroup[event.detail.field],
        event.detail.value
      );
      debugLog(
        this.dbg,
        '>>> handleTerminalInfos() -- curStore.picklistGroup[event.detail.field]: ' +
          JSON.stringify(curStore.picklistGroup[event.detail.field])
      );
    }

    //Set translated fields
    switch (event.detail.field) {
      case 'isLinkedToCashReg':
        curStore.terminalInfos.isLinkedToCashRegDisplayValue = curStore.picklistGroup[event.detail.field].filter(
          (elem) => elem.key === event.detail.value
        )[0].value;
        break;
      case 'terminalModel':
        curStore.terminalInfos.terminalModelDisplayValue = curStore.picklistGroup[event.detail.field].filter(
          (elem) => elem.key === event.detail.value
        )[0].value;
        break;
      // case 'terminalProvider':
      //   this.storeInfos.hasChosenTerminalProvider = true;
      //   break;
    }

    // Check if no duplicate for new terminals
    if ('tid' === event.detail.field) this.checkDuplicateTID(curStore.terminalInfos.tid, curStore.storeId, terminalId);

    // Set placeholder for TID
    //TODO review conditions to cover all possible cases
    if ('terminalModel' === event.detail.field || 'terminalProvider' === event.detail.field)
      this.setTIDPlaceholder(curStore);

    this.savTerminalBtnDisabled = false;
    debugLog(this.dbg, '>>> handleTerminalInfos() -- terminalInfos2: ' + JSON.stringify(curStore.terminalInfos));
    debugLog(
      this.dbg,
      '>>> handleTerminalInfos() -- this.storeInfos.terminalInfos3: ' + JSON.stringify(this.storeInfos.terminalInfos)
    );
    debugLog(this.dbg, '>>> handleTerminalInfos() -- END');
  }

  handleTerminalProvider(event) {
    debugLog(this.dbg, 'handleTerminalProvider -- START');
    let curStore = this.storeInfos; // create "alias" to have code lighter and easier to read

    debugLog(this.dbg, 'handleTerminalProvider -- event: ' + JSON.stringify(event));
    debugLog(this.dbg, 'handleTerminalProvider -- curStore: ' + JSON.stringify(curStore));
    //TODO enable terminal models according to provider
    const modelsForSelectedProvider = this.terminalProvidersAndModels[event.detail.value];
    if (!curStore.picklistGroup) curStore.picklistGroup = {};
    curStore.picklistGroup.terminalModel = [];
    curStore.picklistGroup.terminalModel.push({ key: '...', value: '', hidden: true });
    curStore.terminalInfos.terminalModel = '';
    curStore.terminalInfos.terminalModelDisplayValue = ' ';
    let hasOther = false; // In order to display "Other" entry at the end
    modelsForSelectedProvider.forEach((elem) => {
      if (elem === 'Other') {
        hasOther = true;
      } else {
        curStore.picklistGroup.terminalModel.push({ key: elem, value: elem });
      }
    });
    if (hasOther)
      curStore.picklistGroup.terminalModel.push({ key: 'Other', value: this.labels.lb_terminal_model_other });
    debugLog(
      this.dbg,
      'handleTerminalProvider -- picklistGroup.terminalModel: ' + JSON.stringify(curStore.picklistGroup.terminalModel)
    );
    debugLog(
      this.dbg,
      'handleTerminalProvider2 -- picklistGroup.terminalModel: ' +
        JSON.stringify(this.storeInfos.picklistGroup.terminalModel)
    );

    this.handleTerminalInfos(event);
  }

  async saveTerminal(event) {
    debugLog(this.dbg, 'saveTerminal -- event.target.id: ' + event.target.id);
    let curStore = this.storeInfos; // create "alias" to have code lighter and easier to read
    let terminalId = curStore.terminalInfos.terminalId
      ? curStore.terminalInfos.terminalId
      : this.getTerminalId(curStore);
    debugLog(this.dbg, 'saveTerminal -- terminalId: ' + terminalId);
    debugLog(this.dbg, 'saveTerminal -- curStore: ' + JSON.stringify(curStore));

    curStore.terminalInfos.cashRegisterProvider = curStore.terminalInfos.cashRegisterProvider
      ? curStore.terminalInfos.cashRegisterProvider
      : ' '; //hack to display column anyway even if no value
    debugLog(
      this.dbg,
      'saveTerminal -- curStore.mid & curStore.terminalInfos.mid2: ' + curStore.mid + ' - ' + curStore.mid2
    );

    debugLog(this.dbg, 'saveTerminal -- curStore.terminalInfos.mid2: ' + curStore.mid2);

    // Reorder terminal columns to adjust datatable display
    let terminalReorderedCols = {
      terminalProvider: curStore.terminalInfos.terminalProvider,
      terminalModelDisplayValue: curStore.terminalInfos.terminalModelDisplayValue,
      tid: curStore.terminalInfos.tid,
      isLinkedToCashRegDisplayValue: curStore.terminalInfos.isLinkedToCashRegDisplayValue,
      cashRegisterProvider: curStore.terminalInfos.cashRegisterProvider,
      terminalModel: curStore.terminalInfos.terminalModel,
      tidformat: curStore.terminalInfos.tidformat,
      isLinkedToCashReg: curStore.terminalInfos.isLinkedToCashReg,
      terminalId: curStore.terminalInfos.terminalId,
      storeId: curStore.terminalInfos.storeId,
      isMastercardOnly: this.mastercardOnlyProviders.includes(curStore.terminalInfos.terminalProvider) ? 'true' : 'false',
      isNew: curStore.terminalInfos.isNew
    };

    curStore.terminalInfos = JSON.parse(JSON.stringify(terminalReorderedCols));

    debugLog(
      this.dbg,
      'saveTerminal -- before checkFields - curStore.terminalInfos: ' + JSON.stringify(curStore.terminalInfos)
    );
    const checkFields = checkRequiredFields(
      this.template.querySelectorAll('[id="' + event.target.id + '"]'),
      this.labels.lb_err_msg_required_field
    );
    debugLog(this.dbg, 'saveTerminal -- checkFields: ' + checkFields);

    const ece_models_ko = this.labels.ece_not_compatible_models.split('|');
    const ece_providers_ko = this.labels.ece_not_compatible_providers.split('|');
    debugLog(this.dbg, 'saveTerminal -- this.labels.terminal_providers_tids: ' + this.labels.terminal_providers_tids);
    debugLog(this.dbg, 'saveTerminal -- this.labels.terminal_models_tids: ' + this.labels.terminal_models_tids);

    const providers_tids = JSON.parse(this.labels.terminal_providers_tids);
    const models_tids = JSON.parse(this.labels.terminal_models_tids);

    let checkTID = {};
    if (curStore.terminalInfos.tid.length != 8) {
      this.showToast(this.labels.lb_error, this.labels.lb_err_msg_tid_length, 'error');
    } else {
      checkTID = isValidTID(
        curStore.terminalInfos,
        this.solution,
        ece_providers_ko,
        ece_models_ko,
        providers_tids,
        models_tids
      );
    }

    debugLog(this.dbg, 'saveTerminal -- checkTID1: ' + JSON.stringify(checkTID));

    if (!checkTID.isValid) {
      switch (checkTID.errorMsg) {
        case 'Not_compatible_ECE':
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_tid_notcompatible_ece, 'error');
          break;
        case 'Wrong_TID':
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_tid, 'error');
          break;
      }
    } else {
      // Check if duplicate TID (either existing or within the ones that have just been filled)
      checkTID = await this.checkDuplicateTID(curStore.terminalInfos.tid, curStore.storeId, terminalId);
      debugLog(this.dbg, 'saveTerminal -- checkTID2: ' + JSON.stringify(checkTID));
      // debugLog(this.dbg, "saveTerminal -- checkTID2 isValid: " + checkTID.isValid);
    }

    debugLog(this.dbg, 'saveTerminal -- checkFields && checkTID.isValid: ' + checkFields + ' - ' + checkTID.isValid);
    if (checkFields && checkTID.isValid) {
      debugLog(this.dbg, 'saveTerminal -- checkFields && checkTID.isValid OK ');
      if (curStore.terminalInfos.terminalId) {
        // case existing terminal, then update
        debugLog(this.dbg, 'saveTerminal -- Update: ' + curStore.terminalInfos.terminalId);
        // Update array used for all terminals linked to the merchant
        const terminalIndex = curStore.terminalsList.findIndex(
          (terminal) => terminal.terminalId === curStore.terminalInfos.terminalId
        );
        curStore.terminalsList.splice(terminalIndex, 1, JSON.parse(JSON.stringify(curStore.terminalInfos)));
      } else {
        // case new terminal, then insert
        //Set storeID in order to link terminals to the right store
        debugLog(this.dbg, 'saveTerminal -- Insert');
        debugLog(this.dbg, 'saveTerminal -- curStore.terminalInfos: ' + JSON.stringify(curStore.terminalInfos));
        if (curStore.storeId) {
          debugLog(this.dbg, 'saveTerminal -- curStore.storeId: ' + curStore.storeId);
          curStore.terminalInfos.terminalId = this.getTerminalId(curStore);
          debugLog(this.dbg, 'saveTerminal -- curStore.terminalInfos.terminalId: ' + curStore.terminalInfos.terminalId);
          curStore.terminalInfos.storeId = curStore.storeId;
          curStore.terminalsList.push(JSON.parse(JSON.stringify(curStore.terminalInfos)));
          this.setRowIndex(curStore.terminalInfos, curStore.terminalsList, 'terminalId');
          // this.terminalsStoreIdList.push(curStore.terminalInfos); //Used for the display
        } else {
          //TODO handle this error case, check if possible?
          debugLog(this.dbg, 'saveTerminal -- ***case no curStore.storeId*** ' + curStore.storeId);
        }
      }
      debugLog(this.dbg, 'saveTerminal - curStore.terminalsList = ' + JSON.stringify(curStore.terminalsList));
      this.merchantInfos.storesList.forEach((store) => {
        if (store.storeId == curStore.storeId) {
          store.mid = curStore.mid;
          store.terminalsList = JSON.parse(JSON.stringify(curStore.terminalsList));
        }
      });

      this.showToast(this.labels.lb_success, this.labels.lb_msg_update_success, 'success');
      this.savTerminalBtnDisabled = true;
      // this.template.querySelector('[data-id="' + curStore.rowIndex + '"]').scrollIntoView();
      curStore.showCreateAcceptor = false;
      this.hideCreateTerminalBlock = true;
    }

    debugLog(this.dbg, 'saveTerminal -- ***END***');
  }

  async checkDuplicateMID(mid, subMid, storeId) {
    debugLog(this.dbg, 'checkDuplicateMID -- ***START***');
    debugLog(this.dbg, '>>> checkDuplicateMID() - Start - mid/subMid: ' + mid + ' - ' + subMid);

    this.lastMIDErrMsg = '';
    if (mid) {
      try {
        // check if existing MID / SubMID in database
        this.isMIDChecked = await checkExistingAcceptor({ idType: 'mid', id1: mid, id2: subMid });
        if (!this.isMIDChecked) {
          this.lastMIDErrMsg = subMid
            ? this.labels.lb_err_msg_existing_mid_submid
            : this.labels.lb_err_msg_existing_mid;
        } else {
          this.merchantInfos.storesList.forEach((store) => {
            if (store.storeId != storeId) {
              if (store.mid == mid) {
                if (!store.subMid && !subMid) {
                  this.isMIDChecked = false;
                  this.lastMIDErrMsg = buildTemplate(this.labels.lb_err_msg_mid_linked_to_store, [store.name]);
                }
                if (store.subMid && subMid && store.subMid == subMid) {
                  this.isMIDChecked = false;
                  this.lastMIDErrMsg = buildTemplate(this.labels.lb_err_msg_submid_linked_to_store, [store.name]);
                }
              }
              if (store.mid2 == mid) {
                if (!store.subMid2 && !subMid) {
                  this.isMIDChecked = false;
                  this.lastMIDErrMsg = this.labels.lb_err_msg_mid_linked_to_online;
                }
                if (store.subMid2 && subMid && store.subMid2 == subMid) {
                  this.isMIDChecked = false;
                  this.lastMIDErrMsg = this.labels.lb_err_msg_submid_linked_to_online;
                }
              }
            }
          });

          if (this.storeInfos.mid2 == mid) {
            if (!this.storeInfos.subMid2 && !subMid && this.storeInfos.mid == mid) {
              this.isMIDChecked = false;
              this.lastMIDErrMsg = this.labels.lb_err_msg_mid_linked_to_online;
            }
            if (
              this.storeInfos.subMid2 &&
              subMid &&
              this.storeInfos.subMid2 == subMid &&
              this.storeInfos.subMid == subMid
            ) {
              this.isMIDChecked = false;
              this.lastMIDErrMsg = this.labels.lb_err_msg_submid_linked_to_online;
            }
          }
        }
      } catch (error) {
        debugLog(this.dbg, '>>> checkDuplicateMID() - error ' + error + ' --- Stringify: ' + JSON.stringify(error));
      }
    } else {
      if (subMid) {
        this.isMIDChecked = false;
        this.lastMIDErrMsg = this.labels.lb_err_msg_mid;
      }
    }
    debugLog(this.dbg, '>>> checkDuplicateMID() - this.isMIDChecked ' + this.isMIDChecked);

    if (this.lastMIDErrMsg == '') this.isMIDChecked = true;

    if (!this.isMIDChecked) this.showToast(this.labels.lb_error, this.lastMIDErrMsg, 'error');
    // return this.isMIDChecked;
  }

  async checkDuplicateTID(tid, storeId, terminalId) {
    debugLog(this.dbg, '>>> checkDuplicateTID() - Start - tid: ' + tid);
    let result = {
      isValid: true,
      errorMsg: ''
    };

    // Check if no duplicate with the tids existing in SF
    try {
      // check if existing TID in database
      if (tid && !(await checkExistingAcceptor({ idType: 'tid', id1: tid }))) {
        result = { isValid: false, errorMsg: 'Existing_TID' };
        this.showToast(this.labels.lb_error, this.labels.lb_err_msg_existing_tid, 'error');
        debugLog(this.dbg, '>>> checkDuplicateTID() - result Existing_TID: ' + JSON.stringify(result));
      }
      // check if existing TID in current datas (filled by user)
      if (result.isValid) {
        // Check if no duplicate with the tids that have just been filled
        debugLog(
          this.dbg,
          '>>> checkDuplicateTID() - this.merchantInfos.storesList: ' + JSON.stringify(this.merchantInfos.storesList)
        );
        let nbTids = 0;
        this.merchantInfos.storesList.forEach((store) => {
          // store.terminalsList.forEach((terminal) => terminal.tid === tid ? nbTids++ : nbTids);
          store.terminalsList.forEach((terminal) => {
            terminal.tid === tid && (terminal.terminalId != terminalId || store.storeId != storeId) ? nbTids++ : nbTids;
            debugLog(this.dbg, '>>> checkDuplicateTID() - checkdup TID: ' + terminal.tid + ' VS ' + tid);
            debugLog(this.dbg, '>>> checkDuplicateTID() - nbTids: ' + nbTids);
          });
        });
        if (nbTids > 0) {
          result = { isValid: false, errorMsg: 'Duplicate_TID' };
          this.showToast(this.labels.lb_error, this.labels.lb_err_msg_dup_tid, 'error');
        }
        debugLog(this.dbg, '>>> checkDuplicateTID() - result Duplicate_TID0: ' + result);
        debugLog(this.dbg, '>>> checkDuplicateTID() - result Duplicate_TID: ' + JSON.stringify(result));
      }
      debugLog(this.dbg, '>>> checkDuplicateTID() - END. result: ' + JSON.stringify(result));
      return result;
    } catch (error) {
      debugLog(this.dbg, '>>> checkDuplicateTID() - error ' + error + ' --- Stringify: ' + JSON.stringify(error));
    }
  }

  setTIDPlaceholder(curStore) {
    debugLog(this.dbg, '>>> setTIDPlaceholder() -- Start');
    let provider = curStore.terminalInfos.terminalProvider;
    let model = provider + '_' + curStore.terminalInfos.terminalModel;
    let providersModels = Object.assign(
      JSON.parse(this.labels.terminal_providers_tids),
      JSON.parse(this.labels.terminal_models_tids)
    );

    let paramsValues = [];
    if (providersModels.hasOwnProperty(model) || providersModels.hasOwnProperty(provider)) {
      let firstDigits = providersModels[model] || providersModels[provider];

      if (Array.isArray(firstDigits)) {
        let format = '';
        firstDigits.forEach((value) => (format += value.padEnd(8, '*') + ', '));
        paramsValues.push(format);
        paramsValues.push(firstDigits[0].padEnd(8, '9'));
      } else {
        paramsValues.push(firstDigits.padEnd(8, '*'));
        paramsValues.push(firstDigits.padEnd(8, '9'));
      }
      curStore.terminalInfos.tidformat = buildTemplate(this.labels.lb_tid_place_holder, paramsValues);
    } else {
      debugLog(this.dbg, '>>> setTIDPlaceholder() -- no result');
      curStore.terminalInfos.tidformat = '';
    }

    debugLog(this.dbg, '>>> setTIDPlaceholder() -- END - tidformat = ' + curStore.terminalInfos.tidformat);
  }

  getTerminalId(curStore) {
    debugLog(this.dbg, '>>> getTerminalId() -- START - curStore = ' + JSON.stringify(curStore));
    let terminalIdList = curStore.terminalsList.map((terminal) => terminal.terminalId);
    return terminalIdList.length === 0 ? 1 : Math.max(...terminalIdList) + 1;
  }

  createTerminalsPage() {
    debugLog(this.dbg, 'createTerminalsPage -- ***START*** this.storeInfos: ' + JSON.stringify(this.storeInfos));
    // this.retrieveAcceptorModels();
    if (this.storeInfos?.terminalsList.length == 0) {
      this.storeInfos.terminalsList = [];
      this.storeInfos.terminalsList.push({
        terminalId: 1,
        terminalProvider: ' ',
        terminalModelDisplayValue: ' ',
        tid: ' ',
        cashRegisterProvider: ' ',
        isLinkedToCashRegDisplayValue: ' '
      });
      this.storeInfos.terminalInfos.terminalId = 1; // In order to match first terminal with the first empty record of the data table
      // this.newTerminal();
    }
    this.currentStep = '4';
    debugLog(this.dbg, 'createTerminalsPage -- ***END*** ');
  }

  createCategoriesPage() {
    // this.initCategories();
    this.currentStep = '5';
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

  handleToggleSection(event) {
    // debugLog(this.dbg, "handleToggleSection -- event: " + JSON.stringify(event));
    debugLog(this.dbg, 'handleToggleSection -- event.target.id: ' + event.target.id);
    const sectionIndex = event.target.id.substring(0, event.target.id.indexOf('-'));
    debugLog(this.dbg, 'handleToggleSection -- sectionIndex: ' + sectionIndex);
    debugLog(
      this.dbg,
      'handleToggleSection -- this.merchantInfos.storesList[sectionIndex]: ' +
        JSON.stringify(this.merchantInfos.storesList[sectionIndex])
    );
    let currentState = this.merchantInfos.storesList[sectionIndex].showContent;
    debugLog(this.dbg, 'handleToggleSection -- currentState0: ' + currentState);
    if (currentState == undefined) currentState = false;
    this.merchantInfos.storesList[sectionIndex].showContent = currentState ? false : true;

    debugLog(this.dbg, 'handleToggleSection -- *** END *** ');
  }

  initCategories() {
    debugLog(
      this.dbg,
      '>>> initCategories() ***START*** - params ' + this.merchantInfos.countryCode + ' - ' + this.solution
    );
    this.categorieItems = [];
    let previousCatsCsv = '';
    debugLog(
      this.dbg,
      '>>> initCategories() - this.merchantInfos.storesList[0].chosenCategories: ' +
        JSON.stringify(this.merchantInfos.storesList[0].chosenCategories)
    );
    if (this.merchantInfos.storesList[0].chosenCategories?.length > 0)
      this.merchantInfos.storesList[0].chosenCategories.forEach((cat) => {
        previousCatsCsv += cat.id + ',';
        this.previousCats.push(cat.id);
      });
    debugLog(this.dbg, '>>> initCategories() - this.previousCats: ' + JSON.stringify(this.previousCats));

    debugLog(this.dbg, '>>> initCategories() - previousCatsCsv: ' + previousCatsCsv);

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

        // Init list of categories (1st step) & list of chosen categories (2nd step) for existing stores
        let sortedtreeKeys = Object.keys(this.categories).sort();
        sortedtreeKeys.forEach((elem) => {
          if (this.categories[elem].solution == this.solution) {
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
          } else {
            this.categories[elem].isChecked = true;
            this.chosenCategories.push(this.categories[elem]);
          }
        });

        debugLog(
          this.dbg,
          '>>> initCategories() - this.merchantInfos.storesList[0].chosenCategories: ' +
            JSON.stringify(this.merchantInfos.storesList[0].chosenCategories)
        );

        let chosenCategoriesIds = this.chosenCategories.map((value) => value.id);

        if (this.merchantInfos.storesList[0].chosenCategories.length > 0) {
          this.merchantInfos.storesList[0].chosenCategories.forEach((cat) => {
            debugLog(this.dbg, '>>> initCategories() - cat: ' + JSON.stringify(cat));

            let catFound = false;
            this.categorieItems.forEach((cat2) => {
              if (cat2.id == cat.id && !catFound) {
                cat2.isChecked = cat.isChecked;
                cat2.isMain = cat.isMain;
                catFound = true;
                if (cat2.isChecked && !chosenCategoriesIds.includes(cat2.id)) this.chosenCategories.unshift(cat2);
              }
            });

            if (!catFound) {
              // case category from another solution
              this.chosenCategories.forEach((cat3) => {
                if (cat3.id == cat.id) {
                  cat3.isMain = cat.isMain;
                }
              });
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

  // Message service subscribe and unsubsubscribe for recaptcha component and select language
  subscribeToMessageChannel() {
    subscribe(this.messageContext, selectedLanguage, (message) => this.switchLanguage(message.lang), { scope: APPLICATION_SCOPE } );
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