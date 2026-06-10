/**
 * @author: ALK
 * @date: 05/04/2023
 * @desc: lcerSendExtranetOnboarding
 */

import {api, LightningElement} from 'lwc';
import sendNotification from '@salesforce/apex/APER17_Contact_Management.sendContactOnboardingNotification';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import sendOnboardingTitle from '@salesforce/label/c.LAB_SF_SEND_ONBOARDING_EMAIL_TITLE';
import sendOnboardingSucessMsg from '@salesforce/label/c.LAB_SF_ONBOARDING_EMAIL_MSG';
import processing from '@salesforce/label/c.LAB_SF_PROCESSING';

export default class LcerSendExtranetOnboarding extends LightningElement {
    @api recordId;
    showLoadingSpinner = true;

    label = {
        processing,
        sendOnboardingTitle,
        sendOnboardingSucessMsg
    }

    @api invoke() {
        sendNotification({contactId: this.recordId}).then((errorMsg) => {
            if(errorMsg) {
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.sendOnboardingTitle,
                        message: errorMsg,
                        variant: 'error'
                    }));
            } else {
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.sendOnboardingTitle,
                        message: this.label.sendOnboardingSucessMsg,
                        variant: 'success'
                    }));
            }
        })
    }
}