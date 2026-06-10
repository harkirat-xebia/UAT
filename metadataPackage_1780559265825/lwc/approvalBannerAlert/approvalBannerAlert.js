import { LightningElement, api } from 'lwc';
import checkApprovalConditions from '@salesforce/apex/ApprovalBannerAlertController.checkApprovalConditions';

export default class ApprovalBannerAlert extends LightningElement {

    @api recordId;

    approvalCondtion = '';
    error = '';
    showBanner = false;
    bannerMessage = '';

    connectedCallback(){
        checkApprovalConditions({recordId: this.recordId})
            .then((result) => {
                this.approvalCondtion = result; // Assign data to a property
                if(this.approvalCondtion != 'None'){
                    this.showBanner = true;
                    if(this.approvalCondtion == 'Both'){
                        this.bannerMessage = 'Both discount and finance approvals are required to proceed. Please submit the request for the respective reviews.';
                    }else if(this.approvalCondtion == 'Finance Approval'){
                        this.bannerMessage = `Finance team's approval are required to proceed. Please ensure the necessary details are submitted for review.`;
                    }else if(this.approvalCondtion == 'Discount Approval'){
                        this.bannerMessage = 'Approval is required to proceed with the discount request. Please submit the request for the respective reviews.';
                    }
                }

            })
            .catch((error) => {
                this.error = error;
            });
    }


}