import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAcceptorData from '@salesforce/apex/GenericWithoutSharing.getOnBoardingAcceptor';
import getAcceptorLabelsMetadata from '@salesforce/apex/GenericWithoutSharing.getAutoEnrollmentAcceptorMetadata';
import updateAcceptorData from '@salesforce/apex/GenericWithoutSharing.updateAcceptor';
import insertAcceptorData from '@salesforce/apex/GenericWithoutSharing.insertAcceptor';

export default class ErPortalAcceptor extends NavigationMixin(LightningElement) {
  error;
  @track acceptorId;
  @track acceptorStatus;
  @track acceptorMID;
  @track acceptorSubMID;
  @track acceptorBU;
  @track storeId;
  @track parentStoreId;
  @track parentStoreBU;
  @track labelsMetadata = {};
  mode;
  parentId;
  scope;
  currentPageReference = null;
  urlStateParameters = null;

  isReadOnlyEditable = true;
  isEditModeOn = false;
  showSpinner = false;

  @track statusPicklistValues = [
    {
      key: "Active",
      value: "Active",
      index: 0,
    },
    {
      key: "Inactive",
      value: "Inactive",
      index: 1,
    },
  ];

  @wire(getAcceptorLabelsMetadata)
  wiredAcceptorsLabelsMetadata({ error, data }) {
    if (data) {
      this.labelsMetadata = JSON.parse(data);
    } else if (error) {
      this.error = error;
    }
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.urlStateParameters = currentPageReference.state;
      this.setParametersBasedOnUrl();
    }
  }

  setParametersBasedOnUrl() {
    this.acceptorId = this.urlStateParameters.id;
    this.parentId = this.urlStateParameters.parentid;
    this.mode = this.urlStateParameters.mode;
    this.scope = this.urlStateParameters.scope;
  }

  @wire(getAcceptorData, { acceptorId: "$acceptorId" })
  wiredAcceptors({ error, data }) {
    if (data) {
      this.error = undefined;
      this.acceptorStatus = data.ER_Status__c;
      this.acceptorMID = data.ER_MID_Authorization__c;
      this.acceptorSubMID = data.ER_SubMID_Authorization__c;
      this.storeId = data.ER_Store__c;
      this.acceptorBU = data.ER_BUPicklist__c;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getAcceptorData, { acceptorId: '$acceptorId' })
  wiredAcceptorsCacheUpdate;

  handlePreviousPageAcceptor() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        pageName: 'manage-store'
      },
      state: {
        id: this.storeId,
        mode: "edit",
        scope: this.scope,
        bu: this.acceptorBU,
      },
    });
  }

  handleAcceptorEdit() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        pageName: 'manage-acceptor'
      },
      state: {
        id: this.acceptorId,
        mode: "edit",
        parentid: this.storeId,
        scope: this.scope,
        bu: this.acceptorBU,
      },
    });
  }

  handleCancelSave() {
    if (JSON.stringify(window.location.href).includes('mode=edit')) {
      this[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
          pageName: 'manage-acceptor'
        },
        state: {
          id: this.acceptorId,
          parentid: this.storeId,
          mode: "view",
          scope: this.scope,
          bu: this.acceptorBU,
        },
      });
    }
    if (JSON.stringify(window.location.href).includes('mode=new')) {
      this[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
          pageName: 'manage-acceptor'
        },
        state: {
          id: this.parentStoreId,
          parentid: this.storeId,
          mode: "view",
          scope: this.scope,
          bu: this.parentStoreBU,
        },
      });
    }
  }

  handleStatusChange(event) {
    this.acceptorStatus = event.detail.value;
  }

  handleMIDChange(event) {
    this.acceptorMID = event.detail.value;
  }

  handleSubMIDChange(event) {
    this.acceptorSubMID = event.detail.value;
  }

  handleSaveAcceptor() {
    if (this.acceptorMID === null || this.acceptorMID === "") {
      this.showNotification("Error", "MID field is required.", "error");
    } else {
      if (JSON.stringify(window.location.href).includes("mode=edit")) {
      this.showSpinner = true;
      updateAcceptorData({
        acceptorId: this.acceptorId,
        statusVal: this.acceptorStatus,
        midAuth: this.acceptorMID,
        subMIDAuth: this.acceptorSubMID
      })
        .then((result) => {
          if (result) {
            this.showSpinner = false;
            this.handleCancelSave();
            refreshApex(this.wiredAcceptorsCacheUpdate);
            this.showNotification('Success', 'The Acceptor has been successfully edited.', 'success');
          } else {
            this.showNotification('Error', 'Server-Side Error. Please contact your Salesforce Admin.', 'error');
          }
        })
        .catch((error) => {
          console.log('updateAcceptorData : ' + error);
        });
    }
    //COUL-3723 : Saving the new Acceptor record
    if (JSON.stringify(window.location.href).includes('mode=new')) {
      this.showSpinner = true;
      insertAcceptorData({
        parentId: this.parentStoreId,
        statusVal: typeof this.acceptorStatus == 'undefined' ? 'Active' : this.acceptorStatus,
        midAuth: this.acceptorMID,
        subMIDAuth: this.acceptorSubMID,
        parentBU: this.parentStoreBU
      })
        .then((result) => {
          if (result !== '') {
            this.showSpinner = false;
            this.showNotification('Success', 'The Acceptor has been successfully created.', 'success');
            this[NavigationMixin.Navigate]({
              type: 'comm__namedPage',
              attributes: {
                pageName: 'manage-acceptor'
              },
              state: {
                id: result,
                mode: 'view',
                bu: this.parentStoreBU
              }
            });
          } else {
            this.showNotification('Error', 'Server-Side Error. Please contact your Salesforce Admin.', 'error');
          }
        })
        .catch((error) => {
          console.log('insertAcceptorData : ' + error);
        });
    }
  }
  }

  showNotification(notifTitle, notifMessage, notifVariant) {
    const notificationEvnt = new ShowToastEvent({
      title: notifTitle,
      message: notifMessage,
      variant: notifVariant
    });
    this.dispatchEvent(notificationEvnt);
  }

  renderedCallback() {
    let urlParams = new URLSearchParams(window.location.search);
    this.acceptorId = urlParams.get("id");
    this.parentStoreId = urlParams.get("parentid");
    this.parentStoreBU = urlParams.get("bu");
    this.scope = urlParams.get("scope");
    if (
      JSON.stringify(window.location.href).includes('mode=edit') ||
      JSON.stringify(window.location.href).includes('mode=new')
    ) {
      this.isReadOnlyEditable = false;
      this.isEditModeOn = true;
    }
  }
}