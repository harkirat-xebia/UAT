/**
 * @author : ALK
 * @date : 15/04/2021
 * @desc : switchLanguage
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
//import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import updateUserLanguage from '@salesforce/apex/SwitchLanguageController.updateUserLanguage';
import getLanguages from '@salesforce/apex/SwitchLanguageController.getBULanguages';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//ALK - Custom Labels
import save from '@salesforce/label/c.LABS_SF_Opp_Price_Save';
import processing from '@salesforce/label/c.LAB_SF_LANGUAGE';
import language from '@salesforce/label/c.LAB_SF_LANGUAGE';
import selectLanguage from '@salesforce/label/c.LAB_SF_SELECT_LANGUAGE';
import somethingWentWrong from '@salesforce/label/c.LAB_SF_SOMETHING_WENT_WRONG';
import pleaseSelectLanguage from '@salesforce/label/c.LAB_SF_PLEASE_SELECT_LANGUAGE';
import successMsg from '@salesforce/label/c.LAB_SF_SUCCESS_MSG';

//const USER_FIELDS = ['User.Id', 'User.LanguageLocaleKey', 'User.ER_Business_Unit__c'];

export default class SwitchLanguage extends LightningElement {
  @api recordId;
  @api title;
  @track languageOptions = [];
  showLoadingSpinner = false;
  selectedLanguage;

  //@wire(getRecord, { recordId: Id, fields: USER_FIELDS }) currentUser;

  label = {
    save,
    processing,
    language,
    selectLanguage,
    somethingWentWrong,
    pleaseSelectLanguage,
    successMsg
  };

  connectedCallback() {
    getLanguages()
      .then((result) => {
        if (result) {
          let languages = [];
          let languageRow = [];
          let defaultValue;
          result.split(';').forEach(function (value) {
            if (value) {
              languageRow = value.split(':');
              defaultValue = languageRow[1];
              languages.push({ label: languageRow[0], value: languageRow[1] });
            }
          });
          this.languageOptions = languages;
          if (languages.length === 1) this.selectedLanguage = defaultValue;
        }
      })
      .catch((error) => {
        this.showLoadingSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.somethingWentWrong,
            message: error.message,
            variant: 'error'
          })
        );
      });
  }

  get languages() {
    return this.languageOptions;
  }

  handleChange(event) {
    this.selectedLanguage = event.detail.value;
    console.log('>>>> ALK - handleChange selectedLanguage : ' + this.selectedLanguage);
  }

  handleSave() {
    if (this.selectedLanguage) {
      let connectedUser = { sobjectType: 'User' };
      connectedUser.Id = Id;
      connectedUser.LanguageLocaleKey = this.selectedLanguage;
      updateUserLanguage({ usr: connectedUser })
        .then((result) => {
          if (!result) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.label.successMsg,
                message: this.label.successMsg,
                variant: 'success'
              })
            );

            console.log('>>>> ALK - this.recordId : ' + this.recordId);
            //getRecordNotifyChange([{recordId: this.recordId}]);
            setTimeout(function () {
              window.location.reload();
            }, 2000);
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.label.somethingWentWrong,
                message: result,
                variant: 'error'
              })
            );
          }
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.label.somethingWentWrong,
              message: error.message,
              variant: 'error'
            })
          );
        });
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.somethingWentWrong,
          message: this.label.pleaseSelectLanguage,
          variant: 'error'
        })
      );
    }
  }
}