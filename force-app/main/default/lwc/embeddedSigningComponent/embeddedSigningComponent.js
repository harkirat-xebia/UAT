import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import sendEnvelope from '@salesforce/apex/EmbeddedSigningController.sendEnvelope';
import getEmbeddedSigningUrl from '@salesforce/apex/EmbeddedSigningController.getEmbeddedSigningUrl';

const FRAMEWORK_SCOPE_ERROR_PREFIX = 'FRAMEWORK_SCOPE_UNDEFINED:';

export default class EmbeddedSigningComponent extends NavigationMixin(LightningElement) {

    template = '0916c5bf-6505-4ad0-b879-859535ef2c45';
    description = 'Embedded Signing';
    @api recordId;

    @track isProcessing = false;
    @track showFrameworkScopeError = false;
    @track errorMessage;

    get isButtonDisabled() {
        return this.isProcessing;
    }

    handleClick() {
        this.showFrameworkScopeError = false;
        this.errorMessage = null;
        this.isProcessing = true;

        sendEnvelope({ template: this.template, description: this.description, recordId: this.recordId })
            .then(envelopeId => getEmbeddedSigningUrl({ envId: envelopeId, url: window.location.href }))
            .then(signingUrl => {
                window.location.href = signingUrl;
            })
            .catch(error => {
                const msg = error?.body?.message || '';
                if (msg.startsWith(FRAMEWORK_SCOPE_ERROR_PREFIX)) {
                    this.showFrameworkScopeError = true;
                } else {
                    this.errorMessage = msg || 'An unexpected error occurred. Please try again.';
                }
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    openScopeFlow() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordAction',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Quote',
                actionName: 'Define_Framework_Scope'
            }
        });
    }
}
