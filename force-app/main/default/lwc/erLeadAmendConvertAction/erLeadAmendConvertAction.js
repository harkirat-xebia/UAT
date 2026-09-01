import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { reduceErrors } from 'c/utils';
import getAmendableContracts from '@salesforce/apex/APER47_LeadAmendment_Management.getAmendableContracts';
import logFromClient from '@salesforce/apex/APER45_ErrorLog_Management.logFromClient';

export default class ErLeadAmendConvertAction extends NavigationMixin(LightningElement) {
    @api recordId;

    candidates = [];
    selectedContractId;
    error;
    isLoading = true;

    /*  The insight row already knows which contract the user clicked. Reached from the
        highlights panel there is no such context, so the candidates are resolved here.
        Apex returns them most recent first, and the most recent eligible one is taken -
        a customer should only ever have one active contract per family anyway. */
    @wire(getAmendableContracts, { leadId: '$recordId' })
    handleCandidates({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.candidates = data;
            this.error = undefined;
            const eligible = data.find((candidate) => candidate.isEligible);
            if (eligible) {
                this.selectedContractId = eligible.contractId;
            }
        } else if (error) {
            this.error = error;
            this.candidates = [];
            // harkirat - cacheable Apex cannot log its own failure, so it is logged from here
            logFromClient({
                sourceComponent: 'erLeadAmendConvertAction.getAmendableContracts',
                message: reduceErrors(error).join(' | '),
                stackTrace: error && error.body ? error.body.stackTrace : null,
                relatedRecordId: this.recordId
            }).catch(() => {
                // swallowed on purpose
            });
        }
    }

    get showPanel() {
        return !!this.selectedContractId;
    }

    get showNothingToAmend() {
        return !this.isLoading && !this.error && !this.selectedContractId;
    }

    // harkirat - blocked candidates are still worth explaining rather than hiding
    get blockedCandidates() {
        return this.candidates.filter((candidate) => !candidate.isEligible && !!candidate.blockedReason);
    }

    handleClose(event) {
        const opportunityId = event && event.detail ? event.detail.opportunityId : null;
        if (opportunityId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: opportunityId, actionName: 'view' }
            });
        }
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}