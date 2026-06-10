import { LightningElement, api,track } from 'lwc';
//import sendFormToPrimaryContact from '@salesforce/apex/GetInfoViaForm.sendFormToPrimaryContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class SendClientFormButton extends LightningElement {
    @api recordId;
    @track isLoading = false;

    // connectedCallback() {
    //     console.log('hiiii',this.recordId);
    //     setTimeout(() => {
    //     if(this.recordId){
    //         this.isLoading = true;
    //         console.log('hiiii 222',this.recordId);
    //         sendFormToPrimaryContact({ quoteId: this.recordId })
    //             .then(() => {
    //                 console.log('hiiii 333 33',this.recordId);
    //                 this.showToast('Success', 'Client form link sent successfully.', 'success');
    //                 this.dispatchEvent(new CloseActionScreenEvent());
    //                 this.isLoading = false;
    //             })
    //             .catch(error => {
    //                 console.log('hiiii 444',this.recordId);
    //                 const msg = error?.body?.message || 'An unexpected error occurred.';
    //                 this.showToast('Error', msg, 'error');
    //                 this.dispatchEvent(new CloseActionScreenEvent());
    //                 this.isLoading = false;
    //             })
    //             .finally(() => {
    //                 setTimeout(() => {
    //                     this.dispatchEvent(new CloseActionScreenEvent());
    //                 }, 1000);
    //             });
    //     }
    //     }, 1000);
    // }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}