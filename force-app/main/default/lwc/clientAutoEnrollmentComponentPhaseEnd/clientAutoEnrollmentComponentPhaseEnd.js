import { LightningElement, api } from 'lwc';
import CELEBRATION_ICON from '@salesforce/resourceUrl/celebIcon';
import PHASE_HEADER from '@salesforce/label/c.PhaseEndHeader';
import SUBHEADER from '@salesforce/label/c.PhaseEndSubHeader';
import WARNING from '@salesforce/label/c.PhaseEndWarning';
import BUTTON_LABEL from '@salesforce/label/c.PhaseEndButtonLabel';
import TABLE_HEADER from '@salesforce/label/c.End_Table_header';
import TABLE_ITEM_1 from '@salesforce/label/c.EndTablePointFirst';
import TABLE_ITEM_2 from '@salesforce/label/c.EndTablePointSecond';
import BE_BUTTON_LINK from '@salesforce/label/c.PhaseEndButtonLinkBE';
import LU_BUTTON_LINK from '@salesforce/label/c.PhaseEndButtonLinkLU';

export default class ClientAutoEnrollmentComponentPhaseEnd extends LightningElement {
    
    @api businessUnit; 
    iconUrl = CELEBRATION_ICON;

    label = {
        header: PHASE_HEADER,
        subheader: SUBHEADER,
        warning: WARNING,
        buttonLabel:BUTTON_LABEL,
        tableHeader: TABLE_HEADER,
        tablePoint1: TABLE_ITEM_1,
        tablePoint2:TABLE_ITEM_2,
        linkBE: BE_BUTTON_LINK,
        linkLU: LU_BUTTON_LINK
    }

    get redirectLink() {
        if (this.businessUnit === 'BE') {
            return this.label.linkBE;
        } else if (this.businessUnit === 'LU') {
            return this.label.linkLU;
        }
        return null;
    }


    handleButtonOnClick(){
        window.open(this.redirectLink, '_blank');
    }
}