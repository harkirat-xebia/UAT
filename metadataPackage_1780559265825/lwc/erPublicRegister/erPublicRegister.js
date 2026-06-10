/**
 * Created by noor goolamnabee on 21/12/2022.
 */
import publicRegister from '@salesforce/apex/PublicRegisterController.getData';
import LABEL_TITLE from '@salesforce/label/c.LAB_SF_PublicRegister_Header';
import REGISTRATION_FIELD from '@salesforce/schema/Account.ER_Registration_Number__c';
import ID_FIELD from '@salesforce/schema/Account.Id';
import { reduceErrors } from 'c/utils';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { api, LightningElement, wire } from 'lwc';

export default class ErPublicRegister extends LightningElement {
  @api recordId;
  @api objectApiName;
  registerData;
  error;
  loaded = false;

  @wire(getRecord, { recordId: '$recordId', fields: [REGISTRATION_FIELD] })
  objectRecord;

  @wire(publicRegister, { accountId: '$recordId' })
  wiredRegisterData({ error, data }) {
    if (data) {
      console.log('data : ' + JSON.stringify(data));
      this.registerData = data;
      this.error = undefined;
      this.loaded = true;
    } else if (error) {
      console.log('data : ' + JSON.stringify(error));
      this.error = error;
      this.registerData = undefined;
      this.loaded = true;
    }
  }

  get title() {
    return this.objectRecord.data
      ? LABEL_TITLE.replace('{0}', this.objectRecord.data.fields.ER_Registration_Number__c.value)
      : null;
  }

  handleSave() {
    this.loaded = false;
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;

    for (let key in this.registerData) {
      if (this.template.querySelector("[data-field='" + this.registerData[key].fieldDataChk + "']").checked) {
        fields[this.registerData[key].fieldData] = this.template.querySelector(
          "[data-field='" + this.registerData[key].fieldData + "']"
        ).value;
      }
    }

    const recordInput = { fields, allowSaveOnDuplicate: true };

    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Record updated',
            variant: 'success'
          })
        );

        this.dispatchEvent(new CloseActionScreenEvent());
      })
      .catch((error) => {
        console.log('error=> ' + JSON.stringify(reduceErrors(error)));
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error updating record',
            message: JSON.stringify(reduceErrors(error)),
            variant: 'error'
          })
        );
        this.loaded = true;
      });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent(event));
  }

  toggleCheckboxes(event) {
    for (let key in this.registerData) {
      this.template.querySelector("[data-field='" + this.registerData[key].fieldDataChk + "']").checked =
        event.target.checked;
    }
  }
}