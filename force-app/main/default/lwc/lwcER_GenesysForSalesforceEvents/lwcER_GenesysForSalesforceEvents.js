/**
 * @author: ALK
 * @date: 22/06/2022
 * @desc: lwcER_GenesysForSalesforceEvents
 */

import { LightningElement, wire } from 'lwc';
import { APPLICATION_SCOPE, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import genesysMessageChannel from '@salesforce/messageChannel/purecloud__ClientEvent__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import changeRecordOwner from '@salesforce/apex/ER_GenesysForSalesforceEvents.changeRecordOwner';
import { NavigationMixin } from 'lightning/navigation';

export default class LwcERGenesysForSalesforceEvents extends LightningElement {
  subscription = null;
  recordId;

  @wire(MessageContext) messageContext;

  subscribeToMessageChannel() {
    console.log('>>>> ALK - subscribeToMessageChannel');
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        genesysMessageChannel,
        (message) => this.handleMessage(message),
        { scope: APPLICATION_SCOPE }
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage(message) {
    console.log('>>>> ALK - handleMessage');
    console.log('>>>> ALK - message : ' + message);

    if (message) {
      console.log('ALK - genesys message payload : ' + JSON.stringify(message));
      console.log('>>>>> ALK - message.type : ' + message.type);
      console.log('>>>>> ALK - message.category : ' + message.category);

      if (
        message.type === 'Interaction' &&
        Object.keys(message.data).length !== 0 &&
        message.data.state === 'CONNECTED' &&
        Object.keys(message.data.attributes).length !== 0
      ) {
        this.recordId = message.data.attributes.sf_urlpop;
        console.log('>>>> ALK - recordId : ' + this.recordId);
        changeRecordOwner({ recordId: this.recordId }).then((result) => {
          if (!result) {
            //this.navigateToRecordPage(this.recordId);
            console.log('ALK - call server success - result ' + result);
          } else {
            this.dispatchToast(result);
          }
        });
      }
    } else this.dispatchToast('No message payload has been received from Genesys');
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  dispatchToast(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error loading contact',
        message: error,
        variant: 'error'
      })
    );
  }

  navigateToRecordPage(recordId) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: recordId,
        actionName: 'view'
      }
    });
  }
}