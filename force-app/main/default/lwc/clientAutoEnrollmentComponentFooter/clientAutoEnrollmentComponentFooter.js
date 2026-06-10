import { LightningElement, wire } from 'lwc';
import { loadScript,loadStyle } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 
import BackToEdenredLink from '@salesforce/label/c.BackToEdenredLink';
import FAQFooterLink from '@salesforce/label/c.FAQFooterLink';
import CookiePolicyFooterLink from '@salesforce/label/c.CookiePolicyFooterLink';
import PrivacyNoticeFooterLink from '@salesforce/label/c.PrivacyNoticeFooterLink';
import LegalNoteFooterLink from '@salesforce/label/c.LegalNoteFooterLink';
import Legal_Notes from '@salesforce/label/c.Legal_Notes';
import EdenredBeFooter from '@salesforce/label/c.EdenredBeFooter';
import HelpCenterFooter from '@salesforce/label/c.HelpCenterFooter';
import CookiePolicyFooter from '@salesforce/label/c.CookiePolicyFooter';
import PrivacyNoticeFooter from '@salesforce/label/c.PrivacyNoticeFooter';

import BackToEdenredLinkLU from '@salesforce/label/c.BackToEdenredLinkLU';
import FAQFooterLinkLU from '@salesforce/label/c.FAQFooterLinkLU';
import CookiePolicyFooterLinkLU from '@salesforce/label/c.CookiePolicyFooterLinkLU';
import PrivacyNoticeFooterLinkLU from '@salesforce/label/c.PrivacyNoticeFooterLinkLU';
import LegalNoteFooterLinkLU from '@salesforce/label/c.LegalNoteFooterLinkLU';
import { CurrentPageReference, NavigationMixin  } from 'lightning/navigation';
import fetchProductsFromProductCode from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchProductsFromProductCode';


export default class ClientAutoEnrollmentComponentFooter extends LightningElement {

    businessUnit;
    productCode;
    language;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() { 
        loadStyle(this, ER_CUSTOM_CSS)
        .then(() => {
            console.log('Custom CSS loaded successfully');
        })
        .catch(error => {
            console.error('Error loading custom CSS:', error);
        }); 
        this.productCode = this.currentPageReference.state.product;
        this.language = this.currentPageReference.state.language;  
        if(this.productCode){
            this.fetchProductDetails();
        }
    }

    fetchProductDetails(){
            fetchProductsFromProductCode({productCode: this.productCode, language: this.selectedLanguage})
            .then((result)=>{
                this.businessUnit = result.product.ER_BUPicklist__c;
            })
            .catch((error)=>{
                console.error(error);
            })
        }

    label = {
        backToEdenredLink: BackToEdenredLink,
        faqFooterLink: FAQFooterLink,
        cookiePolicyFooterLink: CookiePolicyFooterLink,
        privacyNoticeFooterLink: PrivacyNoticeFooterLink,
        legalNoteFooterLink: LegalNoteFooterLink,
        legalNotesFooter: Legal_Notes,
        edenredBeFooter: EdenredBeFooter,
        helpCenterFooter: HelpCenterFooter,
        cookiePolicyFooter: CookiePolicyFooter,
        privacyNoticeFooter: PrivacyNoticeFooter,
        BackToEdenredLinkLU: BackToEdenredLinkLU,
        FAQFooterLinkLU: FAQFooterLinkLU,
        CookiePolicyFooterLinkLU: CookiePolicyFooterLinkLU,
        PrivacyNoticeFooterLinkLU: PrivacyNoticeFooterLinkLU,
        LegalNoteFooterLinkLU: LegalNoteFooterLinkLU
    };


    get backToEdenredLink() {
        return this.businessUnit === 'LU' ? this.label.BackToEdenredLinkLU : this.label.backToEdenredLink;
    }
    
    get faqFooterLink() {
        return this.businessUnit === 'LU' ? this.label.FAQFooterLinkLU : this.label.faqFooterLink;
    }
    
    get cookiePolicyFooterLink() {
        return this.businessUnit === 'LU' ? this.label.CookiePolicyFooterLinkLU : this.label.cookiePolicyFooterLink;
    }
    
    get privacyNoticeFooterLink() {
        return this.businessUnit === 'LU' ? this.label.PrivacyNoticeFooterLinkLU : this.label.privacyNoticeFooterLink;
    }
    
    get legalNoteFooterLink() {
        return this.businessUnit === 'LU' ? this.label.LegalNoteFooterLinkLU : this.label.legalNoteFooterLink;
    }
    
}