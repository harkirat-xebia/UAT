import { api } from 'lwc';
import LightningModal from 'lightning/modal';

// harkirat - thin wrapper so the insight row can open the shared panel as a modal
export default class ErLeadAmendConvert extends LightningModal {
    @api leadId;
    @api contractId;

    handlePanelClose(event) {
        this.close(event.detail ? event.detail.opportunityId : null);
    }
}