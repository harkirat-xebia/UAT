import { LightningElement, track, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { MessageContext, publish, subscribe, APPLICATION_SCOPE, } from 'lightning/messageService';
import languageList from '@salesforce/messageChannel/Language_List__c';
import selectedLanguage from '@salesforce/messageChannel/Selected_Language__c';

export default class ErPortalHeader extends LightningElement {
  currentPageReference = null;
  urlStateParameters = null;
  @track langList = [];
  @wire(MessageContext)
  messageContext;
  countryCode = null;

  /* Params from Url */
  urlProduct = null;
  urlSourceId = null;
  urlLanguage = null;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      // Extract country code from url
      this.countryCode = window.location.href.split('?')[0].split('-')[1].slice(-1).toUpperCase();
      this.urlStateParameters = currentPageReference.state;
      this.setParametersBasedOnUrl();
    }
  }

  setParametersBasedOnUrl() {
    this.urlProduct = this.urlStateParameters.product || null;
    this.urlSourceId = this.urlStateParameters.sourceId || null;
    this.urlLanguage = this.urlStateParameters.language;
    this.countryCode = this.urlStateParameters.bu != null ? this.urlStateParameters.bu : this.countryCode;
  }

  get productLogo() {
    let logoCode = 'autoEnrollment_';
    if(this.urlProduct && ['BE','LU'].includes(this.countryCode)){
      let prodCode = this.urlProduct ? this.urlProduct.substring(this.urlProduct.indexOf('_')+1, this.urlProduct.indexOf('-')) : 'TRE'; // Get product code from "full" product code. eg. "TRE" for "ERBE_TRE-M"
      logoCode += this.countryCode + '_' + prodCode;
    } else {
      logoCode += 'default';
    }
    let backgroundUrl2 = "/file-asset-public/" + logoCode;
    console.log(">>>>AAM backgroundUrl2 = " + backgroundUrl2);
    return `${backgroundUrl2}`;
  }

  async connectedCallback() {
    this.subscribeToMessageChannel();
  }


  // Message service subscribe and unsubsubscribe for recaptcha component
  subscribeToMessageChannel() {
    console.log('>>> header - subscribeToMessageChannel -- Start');
    subscribe(this.messageContext, languageList, (message) => this.handleLanguageList(message), { scope: APPLICATION_SCOPE } );
    console.log('>>> header - subscribeToMessageChannel -- End');
  }

  // Handler for message received by main component to get languages list
  handleLanguageList(message) {
    console.log('>>> header - handleLanguageList: ' + message);
    this.langList = message;
  }

  // Handler for language change
  handleChangeLang(event) {
    console.log('>>> header - handleChangeLang: ');
    publish(this.messageContext, selectedLanguage, { lang: event.target.value });
  }

}