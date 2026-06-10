/**
 * @description       : erManageStore : to manage stores
 *                      Add Store => /manage-store?mode=new&parentid=fcId
 *                      Click on Store under the FC list => /manage-store?mode=view&id=a0123455
 * @author            : Hassan DAKHCHA
 * @group             :
 * @last modified on  : 08-30-2023
 * @last modified by  : Hassan DAKHCHA
 **/
import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getStoreRecord from '@salesforce/apex/AutoenrollmentManageStore.getStoreRecord';
import getStoreActivities from '@salesforce/apex/AutoenrollmentManageStore.getStoreActivities';
import getStoreTerminals from '@salesforce/apex/AutoenrollmentManageStore.getStoreTerminals';
import manageStoreEvent from '@salesforce/apex/AutoenrollmentManageStore.manageStoreEvent';
import getFCContact from '@salesforce/apex/AutoenrollmentManageStore.getFCContact';
import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getStoreCategories from '@salesforce/apex/AutoenrollmentManageStore.getStoreCategories';
import newStoreInfo from './newStoreInfo.html';
import newStoreActivity from './newStoreActivity.html';
import newStoreMainActivity from './newStoreMainActivity.html';
import editStoreInfo from './editStoreInfo.html';
import editStoreActivity from './editStoreActivity.html';
import editStoreMainActivity from './editStoreMainActivity.html';
import viewStore from './viewStore.html';
import defaultPage from './erManageStore.html';
import { debugLog, formatPicklist } from 'c/erPortalUtils';

export default class ErManageStore extends LightningElement {
  mode = undefined;
  storeId = undefined;
  parentId = undefined;
  part = undefined;
  dbg;
  lang;
  scope;
  @track storeInfos = {};
  @track picklistGroup = {};
  @track labels = {};
  labelsAllLangs = {};
  @track categorieItems = [];
  @track chosenCategories = [];
  @track useFCContact = false;
  @track disableNewStoreInfoNext = true;
  @track disableNewStoreMainCategoryNext = true;
  @track disableNewStoreCategoryNext = true;
  @track disableEditInfoSave = true;
  @track disableEditStoreActivityNext = true;
  @track disableEditStoreMainCategoryNext = true;
  fcContact = {};
  mainCategoriesItems = [];
  mainActivity;
  @track storeActivities = [{ name: '' }];
  @track activitiesColumns;
  @track storeTerminals = [{ status: '', mid: '', submid: '' }];
  @track terminalColumns;
  @track showSpinner = false;

  render() {
    //return newStoreInfo;
    return this.mode == 'new'
      ? newStoreInfo
      : this.mode == 'view'
      ? viewStore
      : this.mode == 'edit' && this.part == 'info'
      ? editStoreInfo
      : this.mode == 'newStoreInfo'
      ? newStoreInfo
      : this.mode == 'newStoreActivity'
      ? newStoreActivity
      : this.mode == 'newStoreMainActivity'
      ? newStoreMainActivity
      : this.mode == 'edit' && this.part == 'activity'
      ? editStoreActivity
      : this.mode == 'edit' && this.part == 'mainactivity'
      ? editStoreMainActivity
      : defaultPage;
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.mode = String(currentPageReference.state?.mode);
      this.storeId = currentPageReference.state?.id;
      this.parentId = currentPageReference.state?.parentid;
      this.bu = currentPageReference.state?.bu;
      this.dbg = currentPageReference.state?.dbg;
      let la = currentPageReference.language ? currentPageReference.language : 'EN';
      this.lang = la.substring(0, 2).toUpperCase();
      this.part = String(currentPageReference.state?.part);
      this.scope =
        currentPageReference.state && currentPageReference.state.scope ? String(currentPageReference.state.scope) : 'M';
    }
    debugLog(this.dbg, '>>> URL PARAMS params => ' + JSON.stringify(currentPageReference));
    debugLog(this.dbg, '>>> URL PARAMS lang => ' + this.lang);
  }

  connectedCallback() {
    let pkGrp = this.picklistGroup;
    pkGrp.country = [];

    // Get all labels for fields, messages, etc...
    getLabels({ country: this.bu, scope: '' })
      .then((data) => {
        this.labelsAllLangs = data;
        this.labels = {
          ...this.labelsAllLangs[this.lang],
          ...this.labelsAllLangs['All']
        };
        this.initCategories();
        this.getFCContactInfo();
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getLabels() - error ' + error);
      });

    getPicklistInfos({
      country: this.bu,
      lang: this.lang,
      scope: ''
    })
      .then((data) => {
        this.picklistGroup.country = formatPicklist(data.pk_country_codes, this.bu);
        this.picklistGroup.storeStatus = formatPicklist(data.pk_store_status, this.bu);
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> getPicklistInfos() - error ' + error);
      });

    if (this.mode == 'new') {
      this.storeInfos.country = this.bu;
    }
    if (
      (this.mode == 'edit' && this.part == 'info') ||
      (this.mode == 'view' && this.storeInfos.parentId === undefined)
    ) {
      // get store info :
      getStoreRecord({ storeId: this.storeId })
        .then((data) => {
          debugLog(this.dbg, '>>> getStoreRecord() - data ' + JSON.stringify(data));
          this.storeInfos = data;
          this.parentId = data.parentId;
          this.checkEnableSaveEditInfoStatus();
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getStoreRecord() - error ' + JSON.stringify(error));
        });
    }
  }

  initCategories() {
    debugLog(this.dbg, '>>> initCategories() ***START***');
    this.categorieItems = [];
    this.activitiesColumns = {
      name: this.labels.lb_store_activities_colname
    };
    this.terminalColumns = {
      status: this.labels.lb_status,
      mid: this.labels.lb_store_mid,
      submid: this.labels.lb_store_sub_mid
    };

    getStoreCategories({ businessUnit: this.bu, lang: this.lang })
      .then((data) => {
        this.categories = JSON.parse(JSON.stringify(data));
        debugLog(this.dbg, '>>> initCategories() - data: ' + JSON.stringify(this.categories));

        let sortedtreeKeys = Object.keys(this.categories).sort();
        sortedtreeKeys.forEach((elem) => {
          this.categories[elem].treeKey = elem;
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

        debugLog(this.dbg, '>>> initCategories() - ***END1*** ' + JSON.stringify(this.categorieItems));

        debugLog(this.dbg, '>>> getStoreActivities() - MODE ' + this.mode + '/' + this.part);
        if (this.mode == 'view' || (this.mode == 'edit' && this.part == 'activity')) {
          // get store activities :
          getStoreActivities({ storeId: this.storeId })
            .then((data) => {
              debugLog(this.dbg, '>>> getStoreActivities() - data ' + JSON.stringify(data));
              // flag existing activities
              this.updateChosenActivities(data);
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> getStoreActivities() - error ' + JSON.stringify(error));
            });

          getStoreTerminals({ storeId: this.storeId })
            .then((terms) => {
              debugLog(this.dbg, '>>> getStoreTerminals() - data ' + JSON.stringify(terms));
              // flag existing activities
              this.updateTerminalList(terms);
            })
            .catch((error) => {
              debugLog(this.dbg, '>>> getStoreTerminals() - error ' + JSON.stringify(error));
            });
        }
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> initCategories() - error ' + error);
        debugLog(this.dbg, '>>> initCategories() - error str ' + JSON.stringify(error));
      });
  }

  getFCContactInfo() {
    if (this.parentId) {
      getFCContact({ fcId: this.parentId })
        .then((data) => {
          debugLog(this.dbg, '>>> getFCContact - data: ' + JSON.stringify(data));
          this.fcContact = data;
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getFCContact - error str ' + JSON.stringify(error));
        });
    }
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
  }

  handleSelectCategorie(event) {
    const curCatId = event.target.id.substring(0, event.target.id.indexOf('-'));
    const isChecked = event.target.checked;
    this.setSelectCategorie(curCatId, isChecked);
  }

  setSelectCategorie(curCatId, isChecked) {
    debugLog(this.dbg, 'setSelectCategorie -- this.chosenCategories: ' + JSON.stringify(this.chosenCategories));
    debugLog(this.dbg, 'setSelectCategorie -- this.categorieItems: ' + JSON.stringify(this.categorieItems));

    this.categorieItems.forEach((cat) => {
      if (cat.id == curCatId) {
        cat.isChecked = isChecked;
        cat.isMain = false;
        let catFound = false;
        if (isChecked) {
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
    this.updateMainActivityCheck();
    debugLog(
      this.dbg,
      'handleSelectCategorie -- ***END*** -- this.chosenCategories: ' + JSON.stringify(this.chosenCategories)
    );
    this.disableNewStoreCategoryNext = this.chosenCategories.length === 0;
    this.disableEditStoreActivityNext = this.chosenCategories.length === 0;
  }

  selectMainCategory(event) {
    this.mainActivity = event.target.id.substring(0, event.target.id.indexOf('-'));
    this.mainCategoriesItems.forEach((cat) => {
      if (cat.value == this.mainActivity) {
        cat.selected = true;
      } else {
        cat.selected = false;
      }
    });
    this.disableNewStoreMainCategoryNext = this.mainActivity === undefined;
    this.disableEditStoreMainCategoryNext = this.mainActivity === undefined;
    debugLog(this.dbg, 'selectMainCategory -- => ' + this.mainActivity);
  }

  updateMainActivityCheck() {
    // fill main category choices :
    this.mainCategoriesItems = [];
    this.chosenCategories.forEach((cat) => {
      this.mainCategoriesItems.push({ label: cat.name, value: cat.id, selected: cat.id == this.mainActivity });
    });
    debugLog(this.dbg, '>>> mainCategoriesItems() ' + JSON.stringify(this.mainCategoriesItems));

    this.disableEditStoreMainCategoryNext = this.mainActivity === undefined;
    this.disableNewStoreMainCategoryNext = this.mainActivity === undefined;
  }

  ///////////////////////////////////////////////////
  ////// New store callbacks and functions :
  //////////////////////////////////////////////////
  newStoreNext() {
    this.mode =
      this.mode == 'newStoreInfo'
        ? 'newStoreActivity'
        : this.mode == 'new'
        ? 'newStoreActivity'
        : this.mode == 'newStoreActivity'
        ? 'newStoreMainActivity'
        : 'newStoreInfo';
  }
  newStorePrevious() {
    this.mode =
      this.mode == 'newStoreActivity'
        ? 'newStoreInfo'
        : this.mode == 'newStoreMainActivity'
        ? 'newStoreActivity'
        : 'newStoreInfo';
  }
  newStoreSave() {
    debugLog(this.dbg, ' >>> save Store ');
    debugLog(this.dbg, '>>> storeInfos ' + JSON.stringify(this.storeInfos));
    debugLog(this.dbg, '>>> chosenCategories ' + JSON.stringify(this.chosenCategories));
    debugLog(this.dbg, '>>> mainActivity ' + JSON.stringify(this.mainActivity));
    let categoriesList = '';
    this.chosenCategories.forEach((elem) => (categoriesList = categoriesList.concat('|', elem.id)));
    categoriesList = categoriesList.replace('|', '');

    // create the store :
    let params =
      '{"fcid":"' +
      this.parentId +
      '",' +
      '"store":' +
      JSON.stringify(this.storeInfos) +
      ',' +
      '"categories":"' +
      categoriesList +
      '",' +
      '"maincategory":"' +
      this.mainActivity +
      '"' +
      '}';

    manageStoreEvent({ eventName: 'manageStoreCreation', params: params })
      .then((data) => {
        debugLog(this.dbg, ' >>> created Store ' + JSON.stringify(data));
        this.redirectToFinancialCenter();
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> createStore - error ' + JSON.stringify(error));
      });
  }
  newStoreCancel() {
    // back to FC
    this.redirectToFinancialCenter();
  }

  ///////////////////////////////////////////////////
  ////// EDIT store callbacks and functions :
  //////////////////////////////////////////////////
  editStoreInfoCancel() {
    // redirect to store
    this.redirectToStore();
  }

  checkEnableSaveEditInfoStatus() {
    // enable/Disable SAVE button
    this.disableEditInfoSave =
      this.storeInfos.name === undefined ||
      this.storeInfos.name.trim() == '' ||
      this.storeInfos.status === undefined ||
      this.storeInfos.status.trim() == '' ||
      this.storeInfos.street === undefined ||
      this.storeInfos.street.trim() == '' ||
      this.storeInfos.city === undefined ||
      this.storeInfos.city.trim() == '' ||
      this.storeInfos.postalCode === undefined ||
      this.storeInfos.postalCode.trim() == '' ||
      this.storeInfos.country === undefined ||
      this.storeInfos.country.trim() == '' ||
      //(!this.useFCContact &&
      this.storeInfos.firstName === undefined ||
      this.storeInfos.firstName.trim() == '' ||
      this.storeInfos.lastName === undefined ||
      this.storeInfos.lastName.trim() == '' ||
      this.storeInfos.ctcEmail === undefined ||
      this.storeInfos.ctcEmail.trim() == '' ||
      this.storeInfos.ctcPhone === undefined ||
      this.storeInfos.ctcPhone.trim() == '';
    //)
  }

  editStoreInfoSave() {
    debugLog(this.dbg, ' >>> save edit Store ');
    debugLog(this.dbg, '>>> storeInfos ' + JSON.stringify(this.storeInfos));

    // create the store :
    let params = '{"id":"' + this.storeId + '",' + '"storeInfos":' + JSON.stringify(this.storeInfos) + '}';
    this.showSpinner = true;
    manageStoreEvent({ eventName: 'manageStoreInfoSave', params: params })
      .then((data) => {
        debugLog(this.dbg, ' >>> saved Store ' + JSON.stringify(data));
        this.redirectAfterTimeout();
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> editStoreInfoSave - error ' + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  editStoreActivityCancel() {
    // redirect to store
    this.redirectToStore();
  }

  editStoreActivityNext() {
    this.part = 'mainactivity';
    this.updateMainActivityCheck();
  }

  editStoreMainActivityPrevious() {
    this.part = 'activity';
  }

  updateChosenActivities(data) {
    if (data.length == 0) return;
    this.storeActivities = [];
    data.forEach((elem) => {
      debugLog(this.dbg, ' >>> ELEM ' + JSON.stringify(elem));
      this.storeActivities.push({ name: elem.Category__r.Name });
      this.setSelectCategorie(elem.Category__c, true);
      if (elem.Main_Category__c == true) {
        this.mainActivity = elem.Category__c;
      }
    });
    debugLog(this.dbg, ' >>> storeActivities ' + JSON.stringify(this.storeActivities));
    debugLog(this.dbg, ' >>> activitiesColumns ' + JSON.stringify(this.activitiesColumns));
  }

  updateTerminalList(data) {
    if (data.length == 0) return;
    this.storeTerminals = [];
    data.forEach((elem) => {
      debugLog(this.dbg, ' >>> ELEM ' + JSON.stringify(elem));
      this.storeTerminals.push({
        status: elem.ER_Status__c,
        mid: elem.ER_MID_Authorization__c,
        submid: elem.ER_SubMID_Authorization__c,
        hasLink: true,
        href: this.getTerminalUrl(elem.Id)
      });
    });
    debugLog(this.dbg, ' >>> updateTerminalList ' + JSON.stringify(this.storeTerminals));
    debugLog(this.dbg, ' >>> terminalColumns ' + JSON.stringify(this.terminalColumns));
  }

  getTerminalUrl(id) {
    let url = document.location.href;
    let urlParts = url.split('/');

    return (
      'https://' +
      urlParts[2] +
      '/s/manage-acceptor?mode=view' +
      '&id=' +
      id +
      '&parentid=' +
      this.storeId +
      '&bu=' +
      this.bu +
      '&scope=' +
      this.scope +
      '&language=' +
      this.lang);
  }

  editStoreActivitySave() {
    // Save store activities
    let categoriesList = '';
    this.chosenCategories.forEach((elem) => {
      categoriesList = categoriesList.concat('|', elem.id);
    });
    categoriesList = categoriesList.replace('|', '');
    // create the store :
    let params =
      '{"id":"' +
      this.storeId +
      '",' +
      '"categories":"' +
      categoriesList +
      '",' +
      '"maincategory":"' +
      this.mainActivity +
      '"' +
      '}';

    this.showSpinner = true;

    debugLog(this.dbg, '>>> categories ' + JSON.stringify(params));
    manageStoreEvent({ eventName: 'manageStoreActivitySave', params: params })
      .then((data) => {
        debugLog(this.dbg, ' >>> saved Store ' + JSON.stringify(data));
        this.redirectAfterTimeout();
      })
      .catch((error) => {
        debugLog(this.dbg, '>>> editStoreInfoSave - error ' + JSON.stringify(error));
        this.showSpinner = false;
      });
  }
  ////////////////////////////////////////////////////

  // Update fields cachup
  handleChangeValue(event) {
    switch (event.detail.field) {
      case 'storeName':
        this.storeInfos.name = event.detail.value.trim();
        break;
      case 'storeStatus':
        this.storeInfos.status = event.detail.value.trim();
        break;
      case 'street':
        this.storeInfos.street = event.detail.value.trim();
        break;
      case 'city':
        this.storeInfos.city = event.detail.value.trim();
        break;
      case 'postalCode':
        this.storeInfos.postalCode = event.detail.value.trim();
        break;
      case 'country':
        this.storeInfos.country = event.detail.value.trim();
        break;
      case 'facebook':
        this.storeInfos.facebook = event.detail.value.trim();
        break;
      case 'website':
        this.storeInfos.website = event.detail.value.trim();
        break;
      case 'phone':
        this.storeInfos.phone = event.detail.value.trim();
        break;
      case 'email':
        this.storeInfos.email = event.detail.value.trim();
        break;
      case 'contactFirstName':
        this.storeInfos.firstName = event.detail.value.trim();
        break;
      case 'contactLastName':
        this.storeInfos.lastName = event.detail.value.trim();
        break;
      case 'contactEmail':
        this.storeInfos.ctcEmail = event.detail.value.trim();
        break;
      case 'contactPhone':
        this.storeInfos.ctcPhone = event.detail.value.trim();
        break;
      default:
        break;
    }
    this.checkEnableNextInfoStatus();
    this.checkEnableSaveEditInfoStatus();

    debugLog(this.dbg, '>>> handleChangeValue()  -- store: ' + JSON.stringify(this.storeInfos));
  }

  handleSameContactAsFC(event) {
    this.useFCContact = event.detail;
    if (this.useFCContact) {
      this.storeInfos.firstName = this.fcContact.firstName;
      this.storeInfos.lastName = this.fcContact.lastName;
      this.storeInfos.ctcEmail = this.fcContact.mail;
      this.storeInfos.ctcPhone = this.fcContact.phone;
    } else {
      this.storeInfos.firstName = '';
      this.storeInfos.lastName = '';
      this.storeInfos.ctcEmail = '';
      this.storeInfos.ctcPhone = '';
    }
    this.checkEnableNextInfoStatus();
    this.checkEnableSaveEditInfoStatus();
  }

  checkEnableNextInfoStatus() {
    // enable/Disable next button
    this.disableNewStoreInfoNext =
      this.storeInfos.name === undefined ||
      this.storeInfos.name.trim() == '' ||
      this.storeInfos.street === undefined ||
      this.storeInfos.street.trim() == '' ||
      this.storeInfos.city === undefined ||
      this.storeInfos.city.trim() == '' ||
      this.storeInfos.postalCode === undefined ||
      this.storeInfos.postalCode.trim() == '' ||
      this.storeInfos.country === undefined ||
      this.storeInfos.country.trim() == '' ||
      //(!this.useFCContact &&
      this.storeInfos.firstName === undefined ||
      this.storeInfos.firstName.trim() == '' ||
      this.storeInfos.lastName === undefined ||
      this.storeInfos.lastName.trim() == '' ||
      this.storeInfos.ctcEmail === undefined ||
      this.storeInfos.ctcEmail.trim() == '' ||
      this.storeInfos.ctcPhone === undefined ||
      this.storeInfos.ctcPhone.trim() == '';
    //)
  }

  redirectToFinancialCenter() {
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-fc?mode=view&id=' +
      this.parentId +
      '&scope=' +
      this.scope +
      '&bu=' +
      this.bu +
      '&language=' +
      this.lang;
    window.location.href = redirectionUrl;
  }

  redirectAfterTimeout() {
    setTimeout(
      function () {
        this.redirectToStore();
        this.showSpinner = false;
      }.bind(this),
      8000
    );
  }

  redirectToStore() {
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-store?mode=view&id=' +
      this.storeId +
      '&bu=' +
      this.bu +
      '&scope=' +
      this.scope +
      '&language=' +
      this.lang;
    window.location.href = redirectionUrl;
  }

  redirectToEditStoreInfo() {
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-store?mode=edit&part=info&id=' +
      this.storeId +
      '&bu=' +
      this.bu +
      '&scope=' +
      this.scope +
      '&language=' +
      this.lang;
    window.location.href = redirectionUrl;
  }
  redirectToEditStoreActivities() {
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-store?mode=edit&part=activity&id=' +
      this.storeId +
      '&bu=' +
      this.bu +
      '&scope=' +
      this.scope +
      '&language=' +
      this.lang;
    window.location.href = redirectionUrl;
  }

  redirectToAddTerminal() {
    let url = document.location.href;
    let urlParts = url.split('/');
    let redirectionUrl =
      'https://' +
      urlParts[2] +
      '/s/manage-acceptor?mode=new&parentid=' +
      this.storeId +
      '&bu=' +
      this.bu +
      '&scope=' +
      this.scope +
      '&language=' +
      this.lang;
    window.location.href = redirectionUrl;
  }
}