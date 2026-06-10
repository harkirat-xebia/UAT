import { LightningElement, track } from 'lwc';
import getQuoteAccountDetails from '@salesforce/apex/GetInfoViaForm.getQuoteAccountDetails';
import submitClientForm from '@salesforce/apex/GetInfoViaForm.submitClientForm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import edenredLogo from '@salesforce/resourceUrl/EdenRedLogoHD';
import SF_BCE_KBO_Number_EN from '@salesforce/label/c.SF_BCE_KBO_Number_EN';
import SF_BCE_KBO_Number_FR from '@salesforce/label/c.SF_BCE_KBO_Number_EN';
import SF_BCE_KBO_Number_NL from '@salesforce/label/c.SF_BCE_KBO_Number_EN';

import SF_Client_Type_EN from '@salesforce/label/c.SF_Client_Type_EN';
import SF_Client_Type_FR from '@salesforce/label/c.SF_Client_Type_EN';
import SF_Client_Type_NL from '@salesforce/label/c.SF_Client_Type_EN';

import SF_Company_Name_And_Form_EN from '@salesforce/label/c.SF_Company_Name_And_Form_EN';
import SF_Company_Name_And_Form_FR from '@salesforce/label/c.SF_Company_Name_And_Form_EN';
import SF_Company_Name_And_Form_NL from '@salesforce/label/c.SF_Company_Name_And_Form_EN';

import SF_Email_EN from '@salesforce/label/c.SF_Email_EN';
import SF_Email_FR from '@salesforce/label/c.SF_Email_EN';
import SF_Email_NL from '@salesforce/label/c.SF_Email_EN';

import SF_Federation_EN from '@salesforce/label/c.SF_Federation_EN';
import SF_Federation_FR from '@salesforce/label/c.SF_Federation_EN';
import SF_Federation_NL from '@salesforce/label/c.SF_Federation_EN';

import SF_First_Name_EN from '@salesforce/label/c.SF_First_Name_EN';
import SF_First_Name_FR from '@salesforce/label/c.SF_First_Name_EN';
import SF_First_Name_NL from '@salesforce/label/c.SF_First_Name_EN';

import SF_Has_Payroll_Agency_EN from '@salesforce/label/c.SF_Has_Payroll_Agency_EN';
import SF_Has_Payroll_Agency_FR from '@salesforce/label/c.SF_Has_Payroll_Agency_EN';
import SF_Has_Payroll_Agency_NL from '@salesforce/label/c.SF_Has_Payroll_Agency_EN';

import SF_Joint_Committee_Number_EN from '@salesforce/label/c.SF_Joint_Committee_Number_EN';
import SF_Joint_Committee_Number_FR from '@salesforce/label/c.SF_Joint_Committee_Number_EN';
import SF_Joint_Committee_Number_NL from '@salesforce/label/c.SF_Joint_Committee_Number_EN';

import SF_Last_Name_EN from '@salesforce/label/c.SF_Last_Name_EN';
import SF_Last_Name_FR from '@salesforce/label/c.SF_Last_Name_EN';
import SF_Last_Name_NL from '@salesforce/label/c.SF_Last_Name_EN';

import SF_Municipality_EN from '@salesforce/label/c.SF_Municipality_EN';
import SF_Municipality_FR from '@salesforce/label/c.SF_Municipality_EN';
import SF_Municipality_NL from '@salesforce/label/c.SF_Municipality_EN';

import SF_Payroll_Agency_EN from '@salesforce/label/c.SF_Payroll_Agency_EN';
import SF_Payroll_Agency_FR from '@salesforce/label/c.SF_Payroll_Agency_EN';
import SF_Payroll_Agency_NL from '@salesforce/label/c.SF_Payroll_Agency_EN';

import SF_Payroll_Handles_Orders_EN from '@salesforce/label/c.SF_Payroll_Handles_Orders_EN';
import SF_Payroll_Handles_Orders_FR from '@salesforce/label/c.SF_Payroll_Handles_Orders_EN';
import SF_Payroll_Handles_Orders_NL from '@salesforce/label/c.SF_Payroll_Handles_Orders_EN';

import SF_Phone_EN from '@salesforce/label/c.SF_Phone_EN';
import SF_Phone_FR from '@salesforce/label/c.SF_Phone_EN';
import SF_Phone_NL from '@salesforce/label/c.SF_Phone_EN';

import SF_Postal_Code_EN from '@salesforce/label/c.SF_Postal_Code_EN';
import SF_Postal_Code_FR from '@salesforce/label/c.SF_Postal_Code_EN';
import SF_Postal_Code_NL from '@salesforce/label/c.SF_Postal_Code_EN';

import SF_Street_EN from '@salesforce/label/c.SF_Street_EN';
import SF_Street_FR from '@salesforce/label/c.SF_Street_EN';
import SF_Street_NL from '@salesforce/label/c.SF_Street_EN';

import SF_Success_message_EN from '@salesforce/label/c.SF_Success_message_EN';
import SF_Success_message_FR from '@salesforce/label/c.SF_Success_message_EN';
import SF_Success_message_NL from '@salesforce/label/c.SF_Success_message_EN';

import SF_VAT_Number_EN from '@salesforce/label/c.SF_VAT_Number_EN';
import SF_VAT_Number_FR from '@salesforce/label/c.SF_VAT_Number_EN';
import SF_VAT_Number_NL from '@salesforce/label/c.SF_VAT_Number_EN';

import SF_Contact_Role_EN from '@salesforce/label/c.SF_Contact_Role_EN';
import SF_Contact_Role_FR from '@salesforce/label/c.SF_Contact_Role_EN';
import SF_Contact_Role_NL from '@salesforce/label/c.SF_Contact_Role_EN';

import SF_Delivery_Site_EN from '@salesforce/label/c.SF_Delivery_Site_EN';
import SF_Delivery_Site_FR from '@salesforce/label/c.SF_Delivery_Site_EN';
import SF_Delivery_Site_NL from '@salesforce/label/c.SF_Delivery_Site_EN';

import SF_Financial_Center_EN from '@salesforce/label/c.SF_Financial_Center_EN';
import SF_Financial_Center_FR from '@salesforce/label/c.SF_Financial_Center_EN';
import SF_Financial_Center_NL from '@salesforce/label/c.SF_Financial_Center_EN';

import SF_Client_Information_EN from '@salesforce/label/c.SF_Client_Information_EN';
import SF_Client_Information_FR from '@salesforce/label/c.SF_Client_Information_EN';
import SF_Client_Information_NL from '@salesforce/label/c.SF_Client_Information_EN';

import SF_Quote_Feedback_EN from '@salesforce/label/c.SF_Quote_Feedback_EN';
import SF_Quote_Feedback_FR from '@salesforce/label/c.SF_Quote_Feedback_EN';
import SF_Quote_Feedback_NL from '@salesforce/label/c.SF_Quote_Feedback_EN';

import SF_Feedback_Helptext_NL from '@salesforce/label/c.SF_Feedback_Helptext_EN';
import SF_Feedback_Helptext_EN from '@salesforce/label/c.SF_Feedback_Helptext_EN';
import SF_Feedback_Helptext_FR from '@salesforce/label/c.SF_Feedback_Helptext_EN';

import SF_Feedback from '@salesforce/label/c.feedbackLabel';

import SF_Language_NL from '@salesforce/label/c.SF_Language_EN';
import SF_Language_FR from '@salesforce/label/c.SF_Language_EN';
import SF_Language_EN from '@salesforce/label/c.SF_Language_EN';

import SF_Salutation_EN from '@salesforce/label/c.SF_Salutation_EN';
import SF_Salutation_FR from '@salesforce/label/c.SF_Salutation_EN';
import SF_Salutation_NL from '@salesforce/label/c.SF_Salutation_EN';

import SF_Country_NL from '@salesforce/label/c.SF_Country_EN';
import SF_Country_FR from '@salesforce/label/c.SF_Country_EN';
import SF_Country_EN from '@salesforce/label/c.SF_Country_EN';

import PRIVATE_LABEL from '@salesforce/label/c.privateLabel';
import PUBLIC_LABEL from '@salesforce/label/c.publicLabel';

import YES_LABEL from '@salesforce/label/c.Yes';
import NO_LABEL from '@salesforce/label/c.No';

import MAIN_CONTACT from '@salesforce/label/c.Operational_Role_Main_Contact';
import INVOICING_CONTACT from '@salesforce/label/c.Operational_Role_Invoicing_Contact';
import ORDER_CONTACT from '@salesforce/label/c.Operational_Role_Order_Contact';
import DELIVERY_CONTACT from '@salesforce/label/c.Operational_Role_Delivery_Contact';

import SF_STREETNUMBER from '@salesforce/label/c.SF_StreetNumber';

import getContactRolePicklists from '@salesforce/apex/GetInfoViaForm.getContactRolePicklists';


export default class ClientInfoForm extends LightningElement {
    @track logoUrl = edenredLogo;
    @track quoteFound = false;
    @track formSubmitted = false;
    @track isLoading = true;
    @track quoteFeedback = '';
    @track feedbackReadOnly = false;
    @track labels = {};

    @track accountData = {};
    @track ocrRoleList = [];
    @track salutationOptions = [];
    @track languageOptions = [];
    @track hasLoaded = false;


    @track financialCenterData = {
        ER_Invoicing_Street__c: '',
        ER_Invoicing_Zip_Code__c: '',
        ER_Invoicing_City__c: '',
        ER_Email__c: '',
        ER_Invoicing_Country__c: ''
    };

    @track deliverySiteData = {
        ER_Street__c: '',
        ER_Zip_Code__c: '',
        ER_City__c: '',
        ER_Country__c: ''
    };

    streetNumberLabel = SF_STREETNUMBER;

    feedbackLabel = SF_Feedback;

    @track activeSections = ['account', 'ocr', 'financial', 'delivery', 'feedback'];

    hasExistingFinancialCenter = false;
    hasExistingDeliverySite = false;
    quoteId;
    hasStyled = false;

    clientTypeOptions = [
        { label: PUBLIC_LABEL, value: 'Public' },
        { label: PRIVATE_LABEL, value: 'Private' }
    ];

    yesNoOptions = [
        { label: YES_LABEL, value: true },
        { label: NO_LABEL, value: false }
    ];

    get hasEditableOCR() {
        return this.ocrRoleList.some(o => !o.readOnly);
    }

    get isFinancialCenterEditable() {
        return !this.hasExistingFinancialCenter;
    }

    get isDeliverySiteEditable() {
        return !this.hasExistingDeliverySite;
    }

    get showSubmitButton() {
        return this.hasEditableOCR || this.isFinancialCenterEditable || this.isDeliverySiteEditable;
    }

    connectedCallback() {
        this.isLoading = true;
        this.quoteId = new URLSearchParams(window.location.search).get('quoteId');

        if (!this.quoteId) {
            this.quoteFound = false;
            this.isLoading = false;
            return;
        }

        getQuoteAccountDetails({ quoteId: this.quoteId })
            .then(({ account, ocrList, financialCenter, deliverySite, quoteFeedback, isFormSubmitted }) => {
                this.quoteFound = !!account;
                console.log('formSubmitted ',isFormSubmitted);
                console.log('ocrList ',ocrList);
                let preferredLang = 'EN';

                if (ocrList && Array.isArray(ocrList)) {
                    const primaryContact = ocrList.find(ocr => ocr.Role === 'Primary Contact');
                    if (primaryContact && primaryContact.Contact?.ER_Language__c) {
                        preferredLang = primaryContact.Contact.ER_Language__c;
                    }
                }
                console.log('Lang',preferredLang);
                this.setLabelsByLanguage(preferredLang.toUpperCase());
                this.formSubmitted = isFormSubmitted === true;

                if (!this.formSubmitted && account) {
                    this.accountData = {
                        ...account,
                        Name: account.Name + (account.ER_Legal_Form__c ? ' ' + account.ER_Legal_Form__c : ''),
                        Client_Type_formula__c: account.Client_Type_formula__c === 'Public' ? 'Public' : 'Private',
                        ERBE_Has_a_Social_secretary__c: !!account.ERBE_Has_a_Social_secretary__c,
                        BE_Social_Secretary_orders__c: !!account.BE_Social_Secretary_orders__c,
                        ER_Not_subject_to_VAT__c: !!account.ER_Not_subject_to_VAT__c
                    };

                    this.quoteFeedback = quoteFeedback || '';
                    this.feedbackReadOnly = !!quoteFeedback;

                    if (financialCenter) {
                        this.financialCenterData = {
                            ER_Invoicing_Street__c: financialCenter.ER_Invoicing_Street__c || '',
                            ER_Invoicing_Zip_Code__c: financialCenter.ER_Invoicing_Zip_Code__c || '',
                            ER_Invoicing_City__c: financialCenter.ER_Invoicing_City__c || '',
                            ER_Email__c: financialCenter.ER_Email__c || '',
                            ER_Invoicing_Country__c: financialCenter.ER_Invoicing_Country__c || ''
                        };
                        this.hasExistingFinancialCenter = true;
                    }

                    if (deliverySite) {
                        this.deliverySiteData = {
                            ER_Street__c: deliverySite.ER_Street__c || '',
                            ER_Zip_Code__c: deliverySite.ER_Zip_Code__c || '',
                            ER_City__c: deliverySite.ER_City__c || '',
                            ER_Country__c: deliverySite.ER_Country__c || ''
                        };
                        this.hasExistingDeliverySite = true;
                    }

                    const defaultRoles = ['Primary', 'Invoicing', 'Delivery', 'Order'];
                    const roleMap = {};
                    if (ocrList?.length) {
                        ocrList.forEach(o => {
                            const key = this.normalizeRole(o.Role);
                            const translatedKey = this.translateRole(o.Role);
                            if (key) {
                                roleMap[key] = {
                                    role: key,
                                    translatedRole: translatedKey,
                                    FirstName: o.Contact?.FirstName || '',
                                    LastName: o.Contact?.LastName || '',
                                    Email: o.Contact?.Email || '',
                                    Phone: o.Contact?.Phone || '',
                                    Salutation: o.Contact?.Salutation || '',
                                    ER_Language__c: o.Contact?.ER_Language__c || '',
                                    readOnly: true
                                };
                            }
                        });
                    }

                    this.ocrRoleList = defaultRoles.map(role => {
                        return roleMap[role] || {
                            role,
                            translatedRole: this.translateRole(role),
                            FirstName: '',
                            LastName: '',
                            Email: '',
                            Phone: '',
                            Salutation: '',
                            ER_Language__c: '',
                            readOnly: false
                        };
                    });
                }

                this.isLoading = false;
                this.hasLoaded = true;
            })
            .catch(error => {
                console.error('Error loading data:', error);
                this.quoteFound = false;
                this.isLoading = false;
                this.hasLoaded = true;
            });

            getContactRolePicklists().then(result => {
                this.salutationOptions = result.Salutation?.map(label => ({ label, value: label })) || [];
                this.languageOptions = result.ER_Language__c?.map(label => ({ label, value: label })) || [];
            })
            .catch(error => {
                console.error('Error loading picklist values:', error);
            });

    }

    setLabelsByLanguage(lang) {
        lang = (lang === 'FR' || lang === 'NL') ? lang : 'EN';

        this.labels = {
            Company_Name_And_Form: this.pickLabel(SF_Company_Name_And_Form_EN, SF_Company_Name_And_Form_FR, SF_Company_Name_And_Form_NL, lang),
            BCE_KBO_Number: this.pickLabel(SF_BCE_KBO_Number_EN, SF_BCE_KBO_Number_FR, SF_BCE_KBO_Number_NL, lang),
            Client_Type: this.pickLabel(SF_Client_Type_EN, SF_Client_Type_FR, SF_Client_Type_NL, lang),
            Email: this.pickLabel(SF_Email_EN, SF_Email_FR, SF_Email_NL, lang),
            Federation: this.pickLabel(SF_Federation_EN, SF_Federation_FR, SF_Federation_NL, lang),
            First_Name: this.pickLabel(SF_First_Name_EN, SF_First_Name_FR, SF_First_Name_NL, lang),
            Last_Name: this.pickLabel(SF_Last_Name_EN, SF_Last_Name_FR, SF_Last_Name_NL, lang),
            Phone: this.pickLabel(SF_Phone_EN, SF_Phone_FR, SF_Phone_NL, lang),
            Street: this.pickLabel(SF_Street_EN, SF_Street_FR, SF_Street_NL, lang),
            Postal_Code: this.pickLabel(SF_Postal_Code_EN, SF_Postal_Code_FR, SF_Postal_Code_NL, lang),
            Municipality: this.pickLabel(SF_Municipality_EN, SF_Municipality_FR, SF_Municipality_NL, lang),
            Joint_Committee_Number: this.pickLabel(SF_Joint_Committee_Number_EN, SF_Joint_Committee_Number_FR, SF_Joint_Committee_Number_NL, lang),
            Payroll_Agency: this.pickLabel(SF_Payroll_Agency_EN, SF_Payroll_Agency_FR, SF_Payroll_Agency_NL, lang),
            Payroll_Handles_Orders: this.pickLabel(SF_Payroll_Handles_Orders_EN, SF_Payroll_Handles_Orders_FR, SF_Payroll_Handles_Orders_NL, lang),
            Has_Payroll_Agency: this.pickLabel(SF_Has_Payroll_Agency_EN, SF_Has_Payroll_Agency_FR, SF_Has_Payroll_Agency_NL, lang),
            VAT_Number: this.pickLabel(SF_VAT_Number_EN, SF_VAT_Number_FR, SF_VAT_Number_NL, lang),
            Success_Message: this.pickLabel(SF_Success_message_EN, SF_Success_message_FR, SF_Success_message_NL, lang),

            Contact_Role: this.pickLabel(SF_Contact_Role_EN, SF_Contact_Role_FR, SF_Contact_Role_NL, lang),
            Delivery_Site: this.pickLabel(SF_Delivery_Site_EN, SF_Delivery_Site_FR, SF_Delivery_Site_NL, lang),
            Financial_Center: this.pickLabel(SF_Financial_Center_EN, SF_Financial_Center_FR, SF_Financial_Center_NL, lang),
            Client_Information: this.pickLabel(SF_Client_Information_EN, SF_Client_Information_FR, SF_Client_Information_NL, lang),
            Quote_Feedback: this.pickLabel(SF_Quote_Feedback_EN, SF_Quote_Feedback_FR, SF_Quote_Feedback_NL, lang),
            Quote_Feedback_Helptext : this.pickLabel(SF_Feedback_Helptext_EN, SF_Feedback_Helptext_FR, SF_Feedback_Helptext_NL, lang),

            Salutation : this.pickLabel(SF_Salutation_EN, SF_Salutation_FR, SF_Salutation_NL, lang),
            Language : this.pickLabel(SF_Language_EN, SF_Language_FR, SF_Language_NL, lang),
            Country : this.pickLabel(SF_Country_EN, SF_Country_FR, SF_Country_NL, lang)
        };
    }

    pickLabel(en, fr, nl, lang) {
        if (lang === 'FR') return fr;
        if (lang === 'NL') return nl;
        return en;
    }


    normalizeRole(label) {
        const cleaned = (label || '').toLowerCase();
        if (cleaned.includes('primary')) return 'Primary';
        if (cleaned.includes('invoic')) return 'Invoicing';
        if (cleaned.includes('deliver')) return 'Delivery';
        if (cleaned.includes('order')) return 'Order';
        return null;
    }

    translateRole(label) {
        const cleaned = (label || '').toLowerCase();
        if (cleaned.includes('primary')) return MAIN_CONTACT;
        if (cleaned.includes('invoic')) return INVOICING_CONTACT;
        if (cleaned.includes('deliver')) return DELIVERY_CONTACT;
        if (cleaned.includes('order')) return ORDER_CONTACT;
        return null;
    }

    get hasPayrollAgencyIsTrue() {
        return this.accountData.ERBE_Has_a_Social_secretary__c;
    }

    handleInput(event) {
        const { id: fieldId, section, role } = event.target.dataset;
        const value = event.target.value;

        if (section === 'ocr' && role && fieldId) {
            this.ocrRoleList = this.ocrRoleList.map(o =>
                o.role === role ? { ...o, [fieldId]: value } : o
            );
        } else if (section === 'financial' && fieldId) {
            this.financialCenterData = { ...this.financialCenterData, [fieldId]: value };
        } else if (section === 'delivery' && fieldId) {
            this.deliverySiteData = { ...this.deliverySiteData, [fieldId]: value };
        } else if (section === 'feedback') {
            this.quoteFeedback = value;
        }
    }

    handleSubmit() {
        this.isLoading = true;
        const missingFields = [];

        const requiredRoles = ['Primary', 'Invoicing', 'Delivery', 'Order'];
        const validOCRs = [];
        const providedRoles = [];

        this.ocrRoleList.forEach(o => {
            if (!o.readOnly) {
                const isFilled = o.FirstName?.trim() && o.LastName?.trim() && o.Email?.trim() && o.Phone?.trim() && o.Salutation?.trim() && o.ER_Language__c?.trim();
                if (isFilled) {
                    validOCRs.push(o);
                    providedRoles.push(o.role);
                } else {
                    if (!o.Salutation?.trim()) missingFields.push(`${o.role} Salutation`);
                    if (!o.ER_Language__c?.trim()) missingFields.push(`${o.role} Language`);
                    if (!o.FirstName?.trim()) missingFields.push(`${o.role} First Name`);
                    if (!o.LastName?.trim()) missingFields.push(`${o.role} Last Name`);
                    if (!o.Email?.trim()) missingFields.push(`${o.role} Email`);
                    if (!o.Phone?.trim()) missingFields.push(`${o.role} Phone`);
                }
            } else {
                providedRoles.push(o.role);
            }
        });

        requiredRoles.forEach(role => {
            if (!providedRoles.includes(role)) {
                missingFields.push(`${role} Contact (all fields required)`);
            }
        });

        if (this.isFinancialCenterEditable) {
            const f = this.financialCenterData;
            if (!f.ER_Invoicing_Street__c?.trim()) missingFields.push('Financial Center Street');
            if (!f.ER_Invoicing_Zip_Code__c?.trim()) missingFields.push('Financial Center Postal Code');
            if (!f.ER_Invoicing_City__c?.trim()) missingFields.push('Financial Center Municipality');
            if (!f.ER_Email__c?.trim()) missingFields.push('Financial Center Email');
            if (!f.ER_Invoicing_Country__c?.trim()) missingFields.push('Financial Center Country');
        }

        if (this.isDeliverySiteEditable) {
            const d = this.deliverySiteData;
            if (!d.ER_Street__c?.trim()) missingFields.push('Delivery Site Street');
            if (!d.ER_Zip_Code__c?.trim()) missingFields.push('Delivery Site Postal Code');
            if (!d.ER_City__c?.trim()) missingFields.push('Delivery Site Municipality');
            if (!d.ER_Country__c?.trim()) missingFields.push('Delivery Site Country');
        }

        if (missingFields.length > 0) {
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Required Fields',
                message: 'Please complete: ' + missingFields.join(', '),
                variant: 'error',
                mode: 'sticky'
            }));
            return;
        }

        const roleLabelMap = {
            'Primary': 'Primary Contact',
            'Invoicing': 'Invoicing Contact',
            'Delivery': 'Delivering Contact',
            'Order': 'Order Contact'
        };

        const payload = {
            quoteId: this.quoteId,
            ocrListJson: validOCRs.length ? JSON.stringify(validOCRs.map(o => ({
                Role: roleLabelMap[o.role] || o.role,
                FirstName: o.FirstName,
                LastName: o.LastName,
                Email: o.Email,
                Phone: o.Phone,
                Salutation: o.Salutation,
                ER_Language__c: o.ER_Language__c
            }))) : null,
            financialCenterJson: this.isFinancialCenterEditable ? JSON.stringify(this.financialCenterData) : null,
            deliverySiteJson: this.isDeliverySiteEditable ? JSON.stringify(this.deliverySiteData) : null,
            quoteFeedback: this.feedbackReadOnly ? null : this.quoteFeedback?.trim()
        };

        submitClientForm(payload)
            .then(() => {
                this.formSubmitted = true;
                this.isLoading = false;
                // this.dispatchEvent(new ShowToastEvent({
                //     title: 'Success',
                //     message: 'Your information was submitted successfully.',
                //     variant: 'success'
                // }));
                setTimeout(() => {
                    window.location.href = 'https://www.edenred.be/fr';
                }, 2000);
            })
            .catch(error => {
                console.error('Submission failed:', error);
                this.isLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong. Please try again later.',
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
    }

    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            c-client-info-form lightning-accordion-section .slds-accordion__summary {
                background-color: #f72717 !important;
                border-radius: 4px;
            }
            c-client-info-form lightning-accordion-section .slds-accordion__summary-content {
                color: white;
            }
        `;
        if (!this.hasStyled) {
            this.template.querySelector('lightning-accordion').appendChild(style);
            this.hasStyled = true;
        }
    }
}