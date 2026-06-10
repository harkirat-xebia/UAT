import { LightningElement, api, track } from 'lwc';
import sendCustomEmail from '@salesforce/apex/QuotePDFController.sendCustomEmailWithPdf';
import getLanguageForQuote from '@salesforce/apex/QuotePDFController.getLanguageForQuote';
import getEmailTemplateBody from '@salesforce/apex/QuotePDFController.getEmailTemplateBody';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class MmSalesENForm extends LightningElement {
    @api recordId;
    @track showModal = true;
    @track subject = 'Your Quote from Edenred';
    @track body = 'Loading email body...';
    isLoading = false;

    connectedCallback() {
        this.isLoading = true;
        setTimeout(() => {
            console.log('this.recordId 222',this.recordId);
            if (this.recordId) {
                this.handleSendClick();
            }
        }, 100);
        this.isLoading = false;
    }

    // fetchTemplate() {
    //     console.log('this.recordId',this.recordId);
    //     getLanguageForQuote({ quoteId: this.recordId })
    //         .then(language => {
    //             if (language === 'FR') {
    //                 this.subject = 'Votre offre Edenred';
    //             } else if (language === 'NL') {
    //                 this.subject = 'Uw Edenred aanbod';
    //             } else {
    //                 this.subject = 'Your Edenred offer';
    //             }
    //             return getEmailTemplateBody({ languageCode: language });
    //         })
    //         .then(templateHtml => {
    //             this.body = templateHtml;
    //         })
    //         .catch(error => {
    //             console.error('Error fetching email template:', error);
    //             this.subject = 'Your Edenred offer';
    //             this.body = 'Dear Customer, <br><br>Please find the attached offer proposal.';
    //         });
    // }

    // handleSubjectChange(event) {
    //     this.subject = event.target.value;
    // }

    // handleBodyChange(event) {
    //     this.body = event.target.value;
    // }

    handleSendClick() {
        this.isLoading = true;
        sendCustomEmail({
            quoteId: this.recordId,
            // subject: this.subject,
            // body: this.body
        })
        .then(() => { 
            console.log('Here 1');  
            this.showToast('Success', 'PDF Generated.', 'success');
            this.closeQuickAction();
        })
        .catch(error => {
            console.log('Here 2'); 
            this.showToast('Error', error.body.message || 'Something went wrong.', 'error');
            this.closeQuickAction();
        })
        .finally(() => {
            console.log('Here 3');
            this.closeQuickAction(); 
            this.isLoading = false;
            // setTimeout(() => {
            //     console.log('this.recordId 222',this.recordId);
            //     window.location.reload();
            // }, 3000);
        });
    }

    // handleCancelClick() {
    //     this.closeQuickAction();
    // }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}