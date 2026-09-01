import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/utils';
import getPreview from '@salesforce/apex/APER47_LeadAmendment_Management.getPreview';
import amendAndConvert from '@salesforce/apex/APER47_LeadAmendment_Management.amendAndConvert';
import logFromClient from '@salesforce/apex/APER45_ErrorLog_Management.logFromClient';
import AMEND_SUCCESS from '@salesforce/label/c.LABS_SF_Amend_Success';
import MULTIPLE_CONTRACTS from '@salesforce/label/c.LABS_SF_Amend_Multiple_Contracts';

export default class ErLeadAmendConvertPanel extends LightningElement {
    @api leadId;
    @api contractId;

    preview;
    error;
    isLoading = true;
    isWorking = false;
    selectedBandId;
    showErrorPopover = false;

    multipleContractsMessage = MULTIPLE_CONTRACTS;

    @wire(getPreview, { leadId: '$leadId', contractId: '$contractId' })
    handlePreview({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.preview = data;
            this.error = undefined;
            // harkirat - server picks the band matching the lead's volume, user may override
            this.selectedBandId = data.selectedPricebookEntryId;
        } else if (error) {
            this.error = error;
            this.preview = undefined;
            this.showErrorPopover = true;
            /*  getPreview is cacheable, so Apex cannot write its own error log - a cacheable
                method may not perform DML. Logging from here is the only way this failure
                reaches ER_Error_Log__c. amendAndConvert logs server side, so it is not
                repeated below. */
            this.logError('getPreview', error);
        }
    }

    /*  Templates compile member expressions to direct property access with no optional chaining,
        so {preview.isEligible} throws on the first render pass - preview is undefined until the
        wire resolves. Every preview reference in the template goes through a getter for that reason. */
    // harkirat - guards the whole detail block, preview is undefined until the wire returns
    get showDetails() {
        return !!this.preview && this.preview.isEligible;
    }

    // harkirat - templates cannot negate, so the disabled state is exposed directly
    get canConfirmDisabled() {
        return !this.preview || !this.preview.isEligible || this.isWorking;
    }

    get showBlocked() {
        return !!this.preview && !this.preview.isEligible && !!this.preview.blockedReason;
    }

    get hasExistingLines() {
        return !!this.preview && this.preview.existingLines.length > 0;
    }

    get existingLines() {
        return this.preview ? this.preview.existingLines : [];
    }

    /*  Grouped by parent service, because the flat list is unreadable: range children are named
        "3 to 15 cards" / "> 15 cards" and mean nothing until you can see which service they price.
        Insertion order is preserved so the groups follow the order the lines came back in. */
    // harkirat - one group per service, falling back to solution then Other
    get groupedLines() {
        if (!this.preview) {
            return [];
        }
        const groups = new Map();
        this.preview.existingLines.forEach((line) => {
            const name = line.parentName || line.solutionName || 'Other';
            if (!groups.has(name)) {
                groups.set(name, []);
            }
            groups.get(name).push(line);
        });
        return [...groups.entries()].map(([name, lines]) => ({ name, lines }));
    }

    // harkirat - a flat product has a single band, so there is nothing to choose between
    get showBandPicker() {
        return !!this.preview && this.preview.availableBands.length > 1;
    }

    get bandOptions() {
        if (!this.preview) {
            return [];
        }
        return this.preview.availableBands.map((band) => ({
            label: this.describeBand(band),
            value: band.pricebookEntryId
        }));
    }

    get selectedBand() {
        if (!this.preview) {
            return undefined;
        }
        const band = this.preview.availableBands.find((item) => item.pricebookEntryId === this.selectedBandId);
        const resolved = band || this.preview.newLine;
        if (!resolved) {
            return undefined;
        }
        const hasRange = resolved.minValue !== null && resolved.minValue !== undefined;
        return {
            ...resolved,
            hasRange,
            rangeText: hasRange ? this.describeRange(resolved) : null
        };
    }

    // harkirat - more than one active contract in this family is a data problem worth steering on
    get showMultipleContractsWarning() {
        return !!this.preview && this.preview.eligibleContractCount > 1;
    }

    // harkirat - the whole point of the modal, what the amendment will actually contain
    get resultingLineCount() {
        return this.preview ? this.preview.existingLines.length + 1 : 0;
    }

    describeBand(band) {
        const range = this.describeRange(band);
        return range ? `${band.productName} (${range})` : band.productName;
    }

    describeRange(band) {
        const min = band.minValue;
        const max = band.maxValue;
        if ((min === null || min === undefined) && (max === null || max === undefined)) {
            return null;
        }
        if (max === null || max === undefined) {
            return `${min} and above`;
        }
        if (min === null || min === undefined) {
            return `up to ${max}`;
        }
        return `${min} to ${max}`;
    }

    handleBandChange(event) {
        this.selectedBandId = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('panelclose'));
    }

    get errorMessages() {
        return this.error ? reduceErrors(this.error) : [];
    }

    get errorIconTitle() {
        return this.errorMessages.join(' | ');
    }

    /*  Without this the click bubbles to the panel handler below, which would close the popover
        in the same tick it was opened. */
    handleErrorIconClick(event) {
        event.stopPropagation();
        this.showErrorPopover = !this.showErrorPopover;
    }

    handlePanelClick() {
        this.showErrorPopover = false;
    }

    handleConfirm() {
        this.isWorking = true;
        this.error = undefined;
        this.showErrorPopover = false;
        amendAndConvert({
            leadId: this.leadId,
            contractId: this.contractId
        })
            .then((opportunityId) => {
                this.dispatchEvent(new ShowToastEvent({ title: AMEND_SUCCESS, variant: 'success' }));
                /*  The host navigates, not this component: NavigationMixin is unreliable from
                    inside a modal or quick action child, and closing here would cancel it. */
                this.dispatchEvent(new CustomEvent('panelclose', { detail: { opportunityId } }));
            })
            .catch((error) => {
                this.error = error;
                this.showErrorPopover = true;
                this.isWorking = false;
            });
    }

    // harkirat - never let a logging failure surface over the error it was reporting
    logError(context, error) {
        logFromClient({
            sourceComponent: 'erLeadAmendConvertPanel.' + context,
            message: reduceErrors(error).join(' | '),
            stackTrace: error && error.body ? error.body.stackTrace : null,
            relatedRecordId: this.leadId
        }).catch(() => {
            // swallowed on purpose
        });
    }
}