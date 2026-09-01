import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import getInsights from '@salesforce/apex/APER46_RecordInsight_Management.getInsights';
import ErLeadAmendConvert from 'c/erLeadAmendConvert';
import MULTIPLE_CONTRACTS from '@salesforce/label/c.LABS_SF_Amend_Multiple_Contracts';

const CATEGORY_REQUIRED = 'Required';
const CATEGORY_RECOMMENDED = 'Recommended';
const CATEGORY_WARNING = 'Warning';
const TYPE_DUPLICATE_LOOKUP = 'Duplicate_Lookup';
const TYPE_RELATED_RECORD_CHECK = 'Related_Record_Check';

const STATUS_OK = 'Ok';
const STATUS_MISSING = 'Missing';

// harkirat - matches on this action type carry a server side eligibility verdict
const ACTION_AMEND_AND_CONVERT = 'Amend_And_Convert';

export default class ErRecordInsights extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    insights;
    error;
    isLoading = true;
    watchedFields;
    wiredInsights;
    lastModifiedStamp;

    // recordId -> URL. lightning-button has no href, so a match could only ever
    // navigate in the same tab - real anchors need a real URL for the browser's
    // own right-click / ctrl-click / middle-click "open in new tab" to work.
    matchUrls = {};

    connectedCallback() {
        // objectApiName is injected by the record page before this runs
        if (this.objectApiName) {
            this.watchedFields = [`${this.objectApiName}.LastModifiedDate`];
        }
    }

    // Supplies the object LABEL so the heading reads "Lead Insights", not "Lead__c Insights"
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    @wire(getInsights, { recordId: '$recordId' })
    handleInsights(result) {
        this.wiredInsights = result;
        if (result.data) {
            this.insights = result.data;
            this.error = undefined;
            this.isLoading = false;
            this.loadMatchUrls(result.data);
        } else if (result.error) {
            this.error = result.error;
            this.insights = undefined;
            this.isLoading = false;
        }
    }

    // GenerateUrl is async (it does not hit the server, but the API is still a
    // Promise), so match hrefs can't be computed inline in the fieldItems getter -
    // resolve them once here and let the getter re-run when matchUrls updates.
    loadMatchUrls(insights) {
        const ids = new Set();
        insights.fields.forEach((item) => {
            (item.matches || []).forEach((match) => ids.add(match.recordId));
        });

        const missingIds = [...ids].filter((id) => !(id in this.matchUrls));
        if (missingIds.length === 0) {
            return;
        }

        Promise.all(
            missingIds.map((id) =>
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: { recordId: id, actionName: 'view' }
                }).then((url) => [id, url])
            )
        ).then((entries) => {
            const updated = { ...this.matchUrls };
            entries.forEach(([id, url]) => {
                updated[id] = url;
            });
            this.matchUrls = updated;
        });
    }

    // Change detector only. Cacheable Apex results live in a different LDS cache
    // partition than record data, so saving a field on this page does not invalidate
    // them - without this the row stays red until a hard browser refresh.
    // LastModifiedDate is used because it exists on every object and is always
    // readable, unlike the configured fields themselves.
    @wire(getRecord, { recordId: '$recordId', fields: '$watchedFields' })
    handleRecordChange({ data }) {
        if (!data) {
            return;
        }
        const stamp = data.fields.LastModifiedDate.value;
        // Comparing stamps rather than a "loaded once" flag avoids a wasted refresh
        // on first render, since the two wires resolve in nondeterministic order.
        if (this.lastModifiedStamp && this.lastModifiedStamp !== stamp && this.wiredInsights) {
            refreshApex(this.wiredInsights);
        }
        this.lastModifiedStamp = stamp;
    }

    get cardTitle() {
        const label = this.objectInfo && this.objectInfo.data ? this.objectInfo.data.label : null;
        return label ? `${label} Insights` : 'Insights';
    }

    get showCard() {
        return this.isLoading || !!this.error || this.hasContent;
    }

    get hasContent() {
        return !!this.insights && this.insights.hasConfig;
    }

    get showFields() {
        return !this.isLoading && !!this.insights && this.insights.fields.length > 0;
    }

    get showMessages() {
        return !this.isLoading && !!this.insights && this.insights.messages.length > 0;
    }

    get hasMissingRequired() {
        return !!this.insights && this.insights.missingRequiredCount > 0;
    }

    get missingRequiredLabel() {
        return `${this.insights.missingRequiredCount} missing`;
    }

    // Mapped once here rather than in the template, because for:each cannot
    // invoke a getter per item.
    get fieldItems() {
        if (!this.insights) {
            return [];
        }
        const decorated = this.insights.fields.map((item) => {
            if (item.insightType === TYPE_RELATED_RECORD_CHECK) {
                return this.decorateRelated(item);
            }
            return item.insightType === TYPE_DUPLICATE_LOOKUP
                ? this.decorateLookup(item)
                : this.decorateField(item);
        });

        // Required rows already satisfied sink to the bottom so the rows still
        // needing attention stay visible without scrolling past clutter. Missing/
        // Attention rows and Recommended rows keep their configured position -
        // only a resolved Required row moves. Two filter passes rather than a
        // sort comparator: each preserves the original relative order within itself.
        const resolved = decorated.filter((item) => item.category === CATEGORY_REQUIRED && item.status === STATUS_OK);
        const pending = decorated.filter((item) => !(item.category === CATEGORY_REQUIRED && item.status === STATUS_OK));
        return [...pending, ...resolved];
    }

    get messageItems() {
        if (!this.insights) {
            return [];
        }
        return this.insights.messages.map((msg) => {
            const isWarning = msg.category === CATEGORY_WARNING;
            return {
                ...msg,
                iconName: isWarning ? 'utility:warning' : 'utility:info',
                iconVariant: isWarning ? 'warning' : ''
            };
        });
    }

    // Polarity comes from Apex via item.status, never inferred from the type here -
    // a duplicate found is bad, a related record found is good, and guessing that
    // client side is how rows end up the wrong colour.
    decorateRelated(item) {
        const missing = item.status === STATUS_MISSING;
        const recommended = missing && item.category === CATEGORY_RECOMMENDED;
        const required = missing && item.category === CATEGORY_REQUIRED;

        return {
            ...item,
            isLookup: false,
            iconName: missing ? 'utility:error' : 'utility:check',
            iconVariant: required ? 'error' : missing ? 'warning' : 'success',
            labelClass: this.labelClassFor(required, recommended),
            rowClass: recommended ? 'insight-row insight-row_recommended' : 'insight-row',
            showBadge: missing,
            badgeText: item.message ? item.message : `${item.label} required`
        };
    }

    decorateField(item) {
        const filled = item.status ? item.status === STATUS_OK : item.isFilled;
        const missing = item.category === CATEGORY_REQUIRED && !filled;
        const recommended = item.category === CATEGORY_RECOMMENDED && !filled;

        return {
            ...item,
            isLookup: false,
            iconName: missing ? 'utility:error' : recommended ? 'utility:info_alt' : 'utility:check',
            iconVariant: missing ? 'error' : recommended ? 'warning' : 'success',
            labelClass: this.labelClassFor(missing, recommended),
            rowClass: recommended ? 'insight-row insight-row_recommended' : 'insight-row',
            showBadge: missing,
            badgeText: item.message ? item.message : CATEGORY_REQUIRED
        };
    }

    // Apex omits a Duplicate_Lookup row entirely when no match was found - a clean
    // field is not an insight worth a permanent green row - so a row reaching here
    // always means a duplicate was found. No "clean" branch to decorate for.
    decorateLookup(item) {
        // harkirat - only rows configured for an action carry a per match verdict worth showing
        const hasAction = item.actionType === ACTION_AMEND_AND_CONVERT;

        /*  Counted from the matches already on the row rather than a second Apex call - the
            duplicate lookup has already narrowed them to this lead's product family. */
        const actionableCount = hasAction ? (item.matches || []).filter((match) => match.canAct).length : 0;

        return {
            ...item,
            showMultipleContractsWarning: actionableCount > 1,
            multipleContractsMessage: MULTIPLE_CONTRACTS,
            isLookup: true,
            iconName: 'utility:warning',
            iconVariant: 'warning',
            labelClass: 'slds-text-body_regular insight-text_recommended',
            rowClass: 'insight-row insight-row_recommended',
            showBadge: false,
            headingText: item.actionLabel,
            matches: (item.matches || []).map((match) => ({
                ...match,
                url: this.matchUrls[match.recordId],
                showEligible: hasAction && match.canAct,
                showBlockedReason: hasAction && !match.canAct && !!match.blockedReason
            }))
        };
    }

    labelClassFor(missing, recommended) {
        if (missing) {
            return 'slds-text-body_regular slds-text-color_error';
        }
        if (recommended) {
            return 'slds-text-body_regular insight-text_recommended';
        }
        return 'slds-text-body_regular slds-text-color_success';
    }

    // harkirat - opens the shared amend panel, then refreshes so the row reflects the new state
    handleActionClick(event) {
        ErLeadAmendConvert.open({
            size: 'small',
            leadId: this.recordId,
            contractId: event.currentTarget.dataset.id
        }).then((opportunityId) => {
            if (!opportunityId) {
                return;
            }
            if (this.wiredInsights) {
                refreshApex(this.wiredInsights);
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: opportunityId, actionName: 'view' }
            });
        });
    }

    handleMatchClick(event) {
        // Ctrl/Cmd/Shift-click or a non-primary button means the user wants a new
        // tab/window - leave the anchor's href alone and let the browser handle it
        // natively rather than hijacking it into an in-app SPA navigation.
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.button !== 0) {
            return;
        }
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                actionName: 'view'
            }
        });
    }
}