import { LightningElement, track, api } from 'lwc';

import getCategoriesGraph from '@salesforce/apex/APER25_CategoriesHierarchyController.getCategoriesGraph';
import getCategoriesTranslations from '@salesforce/apex/APER25_CategoriesHierarchyController.getCategoriesTranslations';
import manageCreationAndDeletion from '@salesforce/apex/APER25_CategoriesHierarchyController.manageCreationAndDeletion';

// Toast Event

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Custom Labels

import SELECT_LANGUAGE from '@salesforce/label/c.LAB_SF_Category_ComponentText_Select_Language';
import ACTUAL_MAIN from '@salesforce/label/c.LAB_SF_Category_ComponentText_Actual_Main';
import NEW_MAIN from '@salesforce/label/c.LAB_SF_Category_ComponentText_New_Main';

// noinspection JSUnusedGlobalSymbols
export default class CategoriesHierarchy extends LightningElement {
  @api recordId;
  @track isLoaded;
  @track mainCategory = { id: null, label: null };
  @track mainCategoryOptions = [];
  @track categoriesGraph;
  @track languageOptions;

  label = {
    ACTUAL_MAIN,
    NEW_MAIN,
    SELECT_LANGUAGE
  };

  _initialSelection = null;
  _initialMainCategoryId = null;

  // region Properties
  get mainCategoryNode() {
    return (function recurse(node) {
      if (node.isChecked && node.isMain) {
        return node;
      }
      for (let i = 0; i < (node.items?.length ?? 0); i++) {
        let mainCategoryNode = recurse(node.items[i]);
        if (mainCategoryNode != null) return mainCategoryNode;
      }
      return null;
    })(this.categoriesGraph[0]);
  }

  get selectedCategoriesNodes() {
    let selectedCategoriesNodes = Array();
    (function recurse(node) {
      if (node.isChecked) {
        selectedCategoriesNodes.push(node);
      }
      node.items?.forEach((n) => recurse(n));
    })(this.categoriesGraph[0]);
    return selectedCategoriesNodes;
  }

  get selectedCategoriesIds() {
    return new Set(this.selectedCategoriesNodes.map((n) => n.itemId));
  }

  get categoriesNodes() {
    let nodes = Array();
    (function recurse(node) {
      nodes.push(node);
      node.items?.forEach((value) => recurse(value));
    })(this.categoriesGraph[0]);
    return nodes;
  }

  get categoriesIds() {
    let ids = Array();
    this.categoriesNodes.forEach((n) => {
      if (n.itemId != null) ids.push(n.itemId);
    });
    return ids;
  }

  get newCategories() {
    return [...this.selectedCategoriesIds].filter((x) => !this._initialSelection.has(x));
  }

  get removedCategories() {
    return [...this._initialSelection].filter((x) => !this.selectedCategoriesIds.has(x));
  }
  // endregion

  async connectedCallback() {
    this.fetchData();
  }

  // region Event Handlers
  handleCategoryClicked(e) {
    console.log(e.detail.clickedTag);
    if (e.detail.clickedTag === 'LIGHTNING-INPUT') {
      this.toggleFlag(e.detail.itemId, 'isChecked');
    }
    if (e.detail.target === 'chevron') {
      this.toggleFlag(e.detail.itemId, 'isExpanded');
    }
    this.updateGraph();
    this.updateMainCategoryOptions();

    console.log(this.newCategories);
    console.log(this.removedCategories);
  }

  handleLanguageSelected(e) {
    this.fetchTranslations(e.detail.value);
  }

  handleMainCategorySelected(e) {
    this.setMainCategory(e.detail.value);
  }

  handleSaveClicked() {
    if (this.mainCategory.id == null) {
      this.displayError('Main Category Required', 'Please choose a main category');
      return;
    }

    let args = {
      categoriesIdToCreate: this.newCategories,
      categoriesIdToDelete: this.removedCategories,
      storeId: this.recordId,
      newMainCategoryId: this.mainCategory.id
    };
    this.isLoaded = true;
    manageCreationAndDeletion(args)
      .then((_) => {
        this.isLoaded = false;
        this.setInitialValues();
        this.displaySuccess('Success', 'Saved.');

        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
      })
      .catch((error) => {
        this.displayError('Error saving records', error.body?.message);
      });
  }
  // endregion

  // region APEX API calls
  fetchData() {
    getCategoriesGraph({ storeId: this.recordId })
      .then((data) => {
        // noinspection JSUnresolvedVariable
        this.categoriesGraph = [JSON.parse(data.tree)];
        this.languageOptions = data.languages.map((l) => ({
          value: l,
          label: l
        }));
        this.setInitialValues();
      })
      .catch((error) => {
        this.displayError('No Categories Found', error.body?.message);
      });
  }

  fetchTranslations(selectedLanguage) {
    getCategoriesTranslations({
      categoriesIds: this.categoriesIds,
      selectedLanguage: selectedLanguage
    })
      .then((data) => {
        this.setTranslatedLabels(data);
      })
      .catch((error) => this.displayError('Failed to fetch translations', error.body?.message));
  }
  // endregion

  // region Graph Helpers
  setTranslatedLabels(translations) {
    (function recurse(node) {
      if (node.itemId in translations) {
        node.label = translations[node.itemId];
      }
      node.items?.forEach((n) => recurse(n));
    })(this.categoriesGraph[0]);
    this.updateGraph();
  }

  toggleFlag(categoryId, flagName) {
    (function recurse(node) {
      if (node.itemId === categoryId) {
        node[flagName] = !(node[flagName] ?? false);
        return;
      }
      for (let i = 0; i < (node.items?.length ?? 0); i++) {
        recurse(node.items[i]);
      }
    })(this.categoriesGraph[0]);
  }
  // endregion

  // region Helpers
  updateMainCategoryOptions() {
    this.mainCategoryOptions = this.selectedCategoriesNodes.map((n) => ({
      value: n.itemId,
      label: n.label
    }));
    let mainCategoryNode = this.mainCategoryNode;
    this.mainCategory = {
      id: mainCategoryNode?.itemId,
      label: mainCategoryNode?.label
    };
    console.log('main: ', JSON.stringify(this.mainCategoryNode));
    console.log('main: ', JSON.stringify(this.mainCategory));
    this.mainCategoryLabel = mainCategoryNode?.label;
    this.mainCategoryId = mainCategoryNode?.id;
  }

  setMainCategory(categoryId) {
    (function recurse(node) {
      node.isMain = node.itemId === categoryId;
      node.items.forEach((n) => recurse(n));
    })(this.categoriesGraph[0]);
    this.updateMainCategoryOptions();
  }

  updateGraph() {
    this.categoriesGraph = [this.categoriesGraph[0]];
  }

  setInitialValues() {
    this._initialSelection = this.selectedCategoriesIds;
    this._initialMainCategoryId = this.mainCategoryNode;
    this.updateMainCategoryOptions();
  }

  displaySuccess(title, message) {
    this.displayToast(title, message, 'success');
  }

  displayError(title, message) {
    this.displayToast(title, message, 'error');
  }

  displayToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }
  // endregion
}